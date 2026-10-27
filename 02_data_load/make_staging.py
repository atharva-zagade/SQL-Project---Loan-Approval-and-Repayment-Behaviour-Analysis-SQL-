import csv

folder ="C:/Users/Zags/OneDrive/Desktop/SQL Project/Home_Loan/"   # fix this line
files = {
    "stg_application_train": "application_train.csv",
    "stg_previous_application": "previous_application.csv",
    "stg_installments_payments": "installments_payments.csv",
}

with open("01_staging.sql", "w") as out:
    for table, fname in files.items():
        path = folder + fname
        with open(path, newline="") as fh:
            header = next(csv.reader(fh))
        cols = ",\n  ".join(f"{c.lower()} TEXT" for c in header)
        out.write(f"DROP TABLE IF EXISTS {table};\n")
        out.write(f"CREATE TABLE {table} (\n  {cols}\n);\n")
        out.write(f"\\copy {table} FROM '{path}' WITH (FORMAT csv, HEADER true);\n\n")

print("Written 01_staging.sql")
