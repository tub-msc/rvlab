# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2025 RVLab Contributors

import socket
import sys
import subprocess
import time
import tty
import termios
import select
from contextlib import contextmanager

class Hostio:
    OBUF_SIZE = 1024
    IBUF_SIZE = 1024

    OBUF      = 0x0003F000
    IBUF      = 0x0003F400
    FLAGS     = 0x0003F800
    RETVAL    = 0x0003F804
    OBUF_WIDX = 0x0003F808
    OBUF_RIDX = 0x0003F80C
    IBUF_WIDX = 0x0003F810
    IBUF_RIDX = 0x0003F814

class OpenOcd:
    def __init__(self, remote_host="127.0.0.1", remote_port=6666, verbose=False):
        self.remote_host = remote_host
        self.remote_port = remote_port
        self.verbose = verbose
        self.conn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    def __enter__(self):
        self.conn.connect((self.remote_host, self.remote_port))
        return self

    def __exit__(self, type, value, traceback):
        try:
            self.cmd("shutdown")
        finally:
            self.conn.close()

    def cmd(self, cmd: str) -> str:
        data = cmd.encode("utf-8") + b'\x1A'
        if self.verbose:
            print(f"[send] {data!r}")
        self.conn.send(data)

        # Read response message ending with 0x1A:
        data = bytes()
        while len(data) == 0 or data[-1] != 0x1A:
            data += self.conn.recv(4096)
        data = data[:-1].decode("utf-8").strip()

        if self.verbose:
            print(f"[recv] {data!r}")

        return data

    def load_image(self, filename):
        self.cmd(f"load_image {filename} 0 elf")
        self.cmd(f"verify_image {filename} 0 elf")
        self.cmd("reg pc 0x80")
        self.cmd("riscv set_mem_access sysbus")

    def readword(self, address):
        raw = self.cmd(f"read_memory 0x{address:08x} 32 1")
        ret = int(raw, 0)
        return ret

    def writeword(self, address, value):
        self.cmd(f"write_memory 0x{address:08x} 32 0x{value:08x}")

    def writebyte(self, address, value):
        waddr = address &~3
        baddr = address & 3
        word = self.readword(waddr)
        word &= ~(0xff<<(baddr*8))
        word |= (value<<(baddr*8))
        self.writeword(waddr, word)

    def hostio_clear(self):
        self.writeword(Hostio.FLAGS, 0)
        self.writeword(Hostio.RETVAL, 0)
        self.writeword(Hostio.OBUF_WIDX, 0)
        self.writeword(Hostio.OBUF_RIDX, 0)
        self.writeword(Hostio.IBUF_WIDX, 0)
        self.writeword(Hostio.IBUF_RIDX, 0)
        self.obuf_ridx = 0
        self.ibuf_widx = 0

    def hostio_read(self):
        widx = self.readword(Hostio.OBUF_WIDX)

        wordaddr_last = -1
        while widx != self.obuf_ridx:
            wordaddr = Hostio.OBUF + (self.obuf_ridx&~3)
            if wordaddr != wordaddr_last:
                word = self.readword(wordaddr)
                wordaddr_last = wordaddr
            char = chr(word >> ((self.obuf_ridx&3)*8) & 0xff)
            if char == '\n':
                sys.stdout.write('\r\n')
            else:
                sys.stdout.write(char)
            sys.stdout.flush()
            self.obuf_ridx = (self.obuf_ridx + 1) & (Hostio.OBUF_SIZE-1)
        
        self.writeword(Hostio.OBUF_RIDX, self.obuf_ridx)

    def hostio_write(self, data):
        ridx = self.readword(Hostio.IBUF_RIDX)
        ibuf_enqueued = Hostio.IBUF_SIZE
        for char in data:
            while ibuf_enqueued >= Hostio.IBUF_SIZE:
                ibuf_enqueued = (self.ibuf_widx - ridx) & (Hostio.IBUF_SIZE - 1)

            self.writebyte(Hostio.IBUF + self.ibuf_widx, ord(char))
            self.ibuf_widx = (self.ibuf_widx + 1) & (Hostio.IBUF_SIZE-1)
            self.writeword(Hostio.IBUF_WIDX, self.ibuf_widx)



    def run_prog(self, elf_filename):
        self.cmd("halt")
        self.cmd("tcl_trace off")
        flags = 0
        self.hostio_clear()        

        print(f"Loading {elf_filename}...")

        self.load_image(elf_filename)
        self.cmd("resume")

        print("Starting program.")

        time.sleep(1)

        old_settings = termios.tcgetattr(sys.stdin.fileno())
        try:
            tty.setraw(sys.stdin.fileno())
            while (flags & 1) == 0:
                flags = self.readword(Hostio.FLAGS)

                self.hostio_read()

                rready, _, _ = select.select([sys.stdin], [], [], 0)
                if len(rready) > 0:
                    c = sys.stdin.read(1)
                    #print(repr(c))
                    if c in ('\x03', '\x04'): #Ctrl+C or Ctrl+D
                        break
                    self.hostio_write(c)
        finally:
            termios.tcsetattr(sys.stdin.fileno(), termios.TCSADRAIN, old_settings)

        retval = self.readword(Hostio.RETVAL)
        print("Execution finished. Return value:", retval)

@contextmanager
def start(openocd_cfg):
    proc = subprocess.Popen(f"xterm -e openocd -f {openocd_cfg}", shell=True)
    time.sleep(1)
    try:
        with OpenOcd() as ocd:
            yield ocd
    finally:
        proc.kill()
        print("Waiting for openocd to finish...")
        proc.wait()
