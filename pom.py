from xhtml2pdf import pisa as pisa
filename = u'test.pdf'

pdf = pisa.CreatePDF("Hello <strong>World</strong>",file(filename, "wb"))
pisa.startViewer(filename)