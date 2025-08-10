# 🆔 PAN Number Validation Project – PostgreSQL  

<p align="center">
  <img src="Images/pan_card_sample.jpg" alt="PAN Card Image" width="450" height="250" />
</p>

## 📖 Overview  
This project focuses on cleaning, validating, and categorising Permanent Account Numbers (PAN) of Indian nationals using **PostgreSQL**.  
The goal is to ensure each PAN number follows the **official government format** and is categorised as either **Valid** or **Invalid** after a set of stringent checks.  

It also demonstrates **data cleaning techniques**, **pattern validation** with PostgreSQL functions, and **summary reporting**.

---

## 🗂️ Dataset Description  
- **Source**: Provided Excel file `PAN Number Validation Dataset.xlsx`  
- **Number of Records**: As per provided dataset  
- **Column**:  
  - `PAN_NUMBER` – Text field containing PAN values  

### 📌 PAN Official Format Rules
A valid PAN:  
- Has **exactly 10 characters**  
- **Format**: `AAAAA1234A`  
  - First 5 characters → Alphabets (A–Z) in uppercase  
    - No adjacent letters can be the same (e.g., `AABCD` ❌)  
    - Not in a sequential order like `ABCDE` ❌  
  - Next 4 characters → Digits (0–9)  
    - No adjacent digits can be the same (`1123` ❌)  
    - Not sequential like `1234` ❌  
  - Last character → Alphabet (A–Z) in uppercase  

---

## 🧹 Data Cleaning Performed  
- Removed **leading/trailing spaces**  
- Converted all entries to **uppercase**  
- Removed **duplicate PAN numbers**  
- Handled **missing / NULL** PAN numbers  
- Filtered out **empty strings**  

---

## 🎯 Objectives  
- Validate each PAN number against government rules  
- Categorise into:
  - **Valid PAN** ✅  
  - **Invalid PAN** ❌  
- Generate a **summary report** showing:  
  - Total records processed  
  - Valid PAN count  
  - Invalid PAN count  
  - Missing or unprocessed PAN count  

---

## 🛠️ Tools & Technologies Used  
- **SQL Dialect**: PostgreSQL  
- **Platform**: pgAdmin  
- **Other Tools**:  
  - Excel → Initial data storage & inspection  
  - CSV → Used for database import  

---

## 🔍 Key Steps in Implementation  

**1️⃣ Data Cleaning – Removing Extra Spaces & Converting to Uppercase**  
```sql
SELECT *
FROM PAN_DATA
WHERE PAN_NUMBER != UPPER(TRIM(PAN_NUMBER));
```

**2️⃣ Removing Duplicates**  
```sql
SELECT PAN_NUMBER, COUNT(*)
FROM PAN_DATA
GROUP BY PAN_NUMBER
HAVING COUNT(*) > 1;
```

**3️⃣ Storing Cleaned Data**  
```sql
CREATE TABLE PAN_CHECK_DATA AS
SELECT DISTINCT UPPER(TRIM(PAN_NUMBER)) AS PAN_ID
FROM PAN_DATA
WHERE PAN_NUMBER IS NOT NULL
  AND TRIM(PAN_NUMBER) <> '';
```

**4️⃣ PAN Validation Function**  
```sql
CREATE OR REPLACE FUNCTION IS_VALID_PAN(PAN_ID TEXT) RETURNS BOOLEAN AS $$
DECLARE
    letter_part TEXT;
    digit_part TEXT;
    i INT;
    is_seq BOOLEAN := TRUE;
BEGIN
    -- Basic regex format check
    IF pan_id !~ '^[A-Z]{5}[0-9]{4}[A-Z]$' THEN
        RETURN FALSE;
    END IF;

    -- Extract parts
    letter_part := substring(pan_id from 1 for 5);
    digit_part  := substring(pan_id from 6 for 4);

    -- Check adjacent same letters
    FOR i IN 1..4 LOOP
        IF substring(letter_part, i, 1) = substring(letter_part, i + 1, 1) THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    -- Check sequential letters
    is_seq := TRUE;
    FOR i IN 1..4 LOOP
        IF ascii(substring(letter_part, i + 1, 1)) != ascii(substring(letter_part, i, 1)) + 1 THEN
            is_seq := FALSE;
            EXIT;
        END IF;
    END LOOP;
    IF is_seq THEN RETURN FALSE; END IF;

    -- Check adjacent same digits
    FOR i IN 1..3 LOOP
        IF substring(digit_part, i, 1) = substring(digit_part, i + 1, 1) THEN
            RETURN FALSE;
        END IF;
    END LOOP;

    -- Check sequential digits
    is_seq := TRUE;
    FOR i IN 1..3 LOOP
        IF cast(substring(digit_part, i + 1, 1) AS INT) != cast(substring(digit_part, i, 1) AS INT) + 1 THEN
            is_seq := FALSE;
            EXIT;
        END IF;
    END LOOP;
    IF is_seq THEN RETURN FALSE; END IF;

    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL IMMUTABLE;
```

**5️⃣ Categorisation into Valid & Invalid PAN**  
```sql
SELECT PAN_ID,
       CASE WHEN IS_VALID_PAN(PAN_ID) THEN 'Valid Pan'
            ELSE 'Invalid Pan'
       END AS STATUS
FROM PAN_CHECK_DATA;
```

**6️⃣ Summary Report**  
```sql
WITH VALIDATION_STATUS AS (
    SELECT PAN_ID,
           CASE WHEN IS_VALID_PAN(PAN_ID) THEN 'Valid Pan'
                ELSE 'Invalid Pan'
           END AS STATUS
    FROM PAN_CHECK_DATA
),
COUNTS AS (
    SELECT (SELECT COUNT(*) FROM PAN_DATA) AS TOTAL_RECORDS_PROCESSED,
           (SELECT COUNT(*) FROM VALIDATION_STATUS WHERE STATUS = 'Valid Pan') AS TOTAL_VALID_PANS,
           (SELECT COUNT(*) FROM VALIDATION_STATUS WHERE STATUS = 'Invalid Pan') AS TOTAL_INVALID_PANS
)
SELECT C.TOTAL_RECORDS_PROCESSED,
       C.TOTAL_VALID_PANS,
       C.TOTAL_INVALID_PANS,
       C.TOTAL_RECORDS_PROCESSED - (C.TOTAL_VALID_PANS + C.TOTAL_INVALID_PANS) AS MISSING_OR_UNPROCESSED
FROM COUNTS C;
```

---

## 📊 Sample Output (Summary Report)  
| Total Records | Valid PANs | Invalid PANs | Missing / Unprocessed |
|---------------|------------|--------------|-----------------------|
| 1000          | 850        | 130          | 20                    |

---

## 📁 Project Structure  
📦 PAN_Validation_PostgreSQL  
├── 📄 pan_validation.sql *(Main script)*  
├── 📁 Data  
│   ├── PAN Number Validation Dataset.xlsx  
│   ├── PAN_Data.csv  
├── 📄 Requirements.pdf *(Project requirements)*  
├── 📄 Output_Summary.png *(Screenshot of summary output)*  
├── 📄 How_To_Upload_Data.docx *(Guide for CSV import in PostgreSQL)*  
└── 📜 README.md  

---

## 🧠 Future Improvements / Next Steps  
- Integrate with **Python** to automate CSV upload & validation  
- Build **Power BI dashboard** to visualise PAN distribution  
- Add **error logs** for invalid PANs with reasons for failure  
- Extend validation for **fake pattern detection**  

---

## 🚀 How to Run the Project  
1. Clone the repository  
2. Create a PostgreSQL database  
3. Import the CSV file into the `PAN_DATA` table  
4. Run `pan_validation.sql` in **pgAdmin**  
5. Review the summary report & validation results  

---

## 📬 Contact  
💼 **LinkedIn**: [Savan Kumar Maurya](https://www.linkedin.com/in/savankrm)  

⭐ *If you found this project useful, please give it a star!*  
