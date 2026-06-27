import io
import pikepdf
import pdfplumber


def extract_text(pdf_path: str, password: str | None = None) -> str:
    """Extract all text from a PDF. Decrypts first if password is provided."""
    pdf_bytes = _decrypt(pdf_path, password) if password else open(pdf_path, "rb").read()

    with pdfplumber.open(io.BytesIO(pdf_bytes)) as pdf:
        pages = [page.extract_text() or "" for page in pdf.pages]

    text = "\n".join(pages).strip()

    if not text:
        text = _ocr_fallback(pdf_bytes)

    return text


def _decrypt(pdf_path: str, password: str) -> bytes:
    with pikepdf.open(pdf_path, password=password) as pdf:
        buf = io.BytesIO()
        pdf.save(buf)
        return buf.getvalue()


def _ocr_fallback(pdf_bytes: bytes) -> str:
    import pytesseract
    from pdf2image import convert_from_bytes

    images = convert_from_bytes(pdf_bytes)
    return "\n".join(pytesseract.image_to_string(img) for img in images)
