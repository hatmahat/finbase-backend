import typer
from pathlib import Path

app = typer.Typer(help="finbase — bank statement ingestion CLI")


@app.command()
def ingest(
    pdf: Path = typer.Argument(..., help="Path to the bank PDF e-statement"),
    wallet: str = typer.Option(..., "--wallet", "-w", help="Wallet name (must match DB)"),
    password: str = typer.Option(None, "--password", "-p", help="PDF password if encrypted"),
):
    """Parse a single PDF e-statement and insert transactions into Supabase."""
    from app.services import ingest as svc

    typer.echo(f"Ingesting {pdf.name} → wallet: {wallet}")
    inserted, skipped = svc.run(str(pdf), wallet, password=password)
    typer.echo(f"Done — {inserted} inserted, {skipped} skipped (duplicates)")


@app.command("ingest-dir")
def ingest_dir(
    folder: Path = typer.Argument(..., help="Folder containing PDF e-statements"),
    wallet: str = typer.Option(..., "--wallet", "-w", help="Wallet name (must match DB)"),
    password: str = typer.Option(None, "--password", "-p", help="PDF password if encrypted"),
):
    """Batch-ingest all PDFs in a folder."""
    from app.services import ingest as svc

    pdfs = sorted(folder.glob("*.pdf"))
    if not pdfs:
        typer.echo("No PDF files found.")
        raise typer.Exit(1)

    total_inserted = total_skipped = 0
    for pdf in pdfs:
        typer.echo(f"  {pdf.name} ...", nl=False)
        inserted, skipped = svc.run(str(pdf), wallet, password=password)
        typer.echo(f" {inserted} inserted, {skipped} skipped")
        total_inserted += inserted
        total_skipped += skipped

    typer.echo(f"\nTotal — {total_inserted} inserted, {total_skipped} skipped")


@app.command("import-csv")
def import_csv(
    csv: Path = typer.Argument(..., help="Path to Simple app CSV export"),
):
    """One-time migration: import historical transactions from Simple app CSV."""
    from app.services import csv_import as svc

    typer.echo(f"Importing {csv.name}")
    inserted, skipped = svc.run(str(csv))
    typer.echo(f"Done — {inserted} inserted, {skipped} skipped (duplicates)")


if __name__ == "__main__":
    app()
