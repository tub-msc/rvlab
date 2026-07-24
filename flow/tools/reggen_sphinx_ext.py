# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 RVLab Contributors

from docutils import nodes
from docutils.parsers.rst import Directive, directives

from .reggen_wrapper import run_reggen
from .reggen import gen_selfdoc
from pathlib import Path
import io
import mistletoe
import re
import tempfile

class ReggenDirective(Directive):
    required_arguments = 1
    optional_arguments = 0
    has_content = False

    def run(self):
        name = self.arguments[0]

        input_hjson_fn = Path.cwd().parent / f'src/design/reggen/{name}.hjson'

        with tempfile.NamedTemporaryFile("r") as f:
            run_reggen(input_hjson_fn, None, None, None, f.name)

            html = f.read()

        #html = f"<h1>{input_hjson_fn}</h1>"
        node = nodes.raw('', html, format='html') 

        return [node]

class ReggenSelfdocDirective(Directive):
    required_arguments = 0
    optional_arguments = 0
    has_content = False

    def run(self):
        buf = io.StringIO()
        gen_selfdoc.document(buf)

        html = mistletoe.markdown(buf.getvalue())

        # Mistletoe emits bare tags; add the classes that Sphinx themes style.
        html = html.replace('<table>', '<table class="docutils align-default">')
        html = re.sub(r'<pre><code[^>]*>', '<div class="highlight"><pre>', html)
        html = html.replace('</code></pre>', '</pre></div>')

        node = nodes.raw('', html, format='html')

        return [node]

def setup(app):
    app.add_directive("reggen", ReggenDirective)
    app.add_directive("reggen-selfdoc", ReggenSelfdocDirective)
    app.add_css_file('css/reg_html.css') 

    return {
        'version': '0.1',
        'parallel_read_safe': True,
        'parallel_write_safe': True,
    }
