# Data-Cleaning-and-Preparation-of-Global-Layoffs-Dataset-Using-MySQL
[![YouTube](https://img.shields.io/badge/Watch%20on-YouTube-red?logo=youtube)](https://youtu.be/X4ee_lMhEmU)
[![Connect with me on LinkedIn](https://img.shields.io/badge/Connect%20with%20me-LinkedIn-blue?logo=linkedin)](https://www.linkedin.com/in/md-nafis-al-zamee-a88a9024b)
#### 📊Project Overview:
This project showcases a thorough data cleaning workflow applied to a real-world global layoffs dataset using MySQL. The raw data was transformed into a clean, standardized, and analysis-ready format through a series of SQL-based operations, reflecting real-world data engineering and ETL best practices.The dataset contains information on layoffs globally, including company, location, industry, total layoffs, percentage laid off, date, company stage, country, and funds raised. The raw data was imported into a MySQL schema named `world_layoffs` and cleaned to enable accurate exploratory data analysis.

---
### 🛠️Technologies and Skills Demonstrated:
- MySQL database creation and management  
- Data import and export via MySQL Workbench  
- Advanced SQL window functions (`ROW_NUMBER()`, `PARTITION BY`)  
- String functions (`TRIM()`, `LIKE`, pattern matching)  
- Data type conversion (`STR_TO_DATE()`, `ALTER TABLE MODIFY`)  
- Self-joins for data imputation  
- Data filtering and deletion for quality assurance  

---
### 🗂️Data Set Details:
- The dataset contains **2,361 records** of layoffs worldwide.
- Key columns include:
  - **Company**: Name of the company issuing layoffs.
  - **Location**: Geographic location of the layoffs.
  - **Industry**: Sector to which the company belongs.
  - **Total Laid Off**: Number of employees laid off.
  - **Percentage Laid Off**: Percentage of the workforce laid off.
  - **Date**: When the layoffs occurred (initially stored as text).
  - **Stage**: Company stage, such as Series B, Post-IPO, or unknown.
  - **Country**: Country of the layoffs.
  - **Funds Raised (Millions)**: Capital raised by the company.
- The dataset was sourced from a GitHub repository for easy access.

---

### 🛠️🧩Key Processes Performed:
1. **Duplicate Detection and Removal**: 
2. **Data Standardization**:  
3. **Handling Nulls and Missing Values**:   
4. **Date Formatting and Data Type Conversion**:  
5. **Column and Row Removal**:
  
---
## 🌟 Key Features & Methodologies
---
### Step 1: Creating Database and Importing Raw Data

- Created a new schema for the project:

![Creating schema](Creating%20schema.png)

- Imported the layoffs dataset into a table named `layoffs` using MySQL’s Table Data Import Wizard, keeping the raw data intact without modifying import settings (e.g., date imported as text).
![Importing Data](importing%20data.png)
---

### Step 2: Creating a Staging Table for Data Cleaning

To preserve raw data integrity and enable safe cleaning, a staging table was created by copying all data from the raw `layoffs` table:

```sql
select *
from layoffs;

create table layoff_staging
like layoffs;
```

This approach aligns with best practices to avoid direct modification of raw data.

---

### Step 3: Removing Duplicate Rows

Since the dataset lacked a unique identifier, duplicates were detected using a window function `ROW_NUMBER()` partitioned by all relevant columns to identify identical rows:

```sql
 select * , 
 Row_number() over(partition by company, location, industry,total_laid_off,'date',stage,country,funds_raised_millions) as row_num
 from layoff_staging;
 
 with duplicate_cte as
	(select * , 
 Row_number()
 over(partition by company, location, industry,total_laid_off,'date',stage,country,funds_raised_millions) as row_num
 from layoff_staging )

 select * from duplicate_cte where row_num>1;
```

After identifying duplicates, a new table `layoffs_staging_2` was created with an additional column `row_num`:

```sql
CREATE TABLE `layoff_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

Select *
from layoff_staging2;

insert into layoff_staging2
 select * , 
 Row_number()
 over(partition by company, location, industry,total_laid_off,'date',stage,country,funds_raised_millions) as row_num
 from layoff_staging;
```

Duplicates (rows where `row_num > 1`) were deleted from this table:

```sql
 Delete 
from layoff_staging2
where row_num>1;
```

the auxiliary column was dropped to clean up the schema:
```sql
alter table layoff_staging2
drop column row_num;
```
Finally, re-enable safe updates after execution

```sql
SET SQL_SAFE_UPDATES = 0;
DELETE FROM layoff_staging2 WHERE row_num > 1;
SET SQL_SAFE_UPDATES = 1; 
```

---

### Step 4: Standardizing Data

#### 4.1 Trimming Whitespace in Company Names

Whitespace inconsistencies were removed using the `TRIM()` function:

```sql
select company, 
 (trim(company))
from layoff_staging2;

update layoff_staging2
set company =trim(company);
```

#### 4.2 Normalizing Industry Labels

Example: Multiple variations of "crypto" such as "cryptocurrency", "crypto", and typos like "crypt" were standardized to "crypto" using pattern matching and update:

```sql
select *
from layoff_staging2
where industry like "crypto%";

update layoff_staging2
set industry = "Crypto"
where industry like "crypto%";
```

#### 4.3 Fixing Country Names with Trailing Characters

A trailing period in some country names was removed using `TRIM(TRAILING ...)`:

```sql
select *
from layoff_staging2
where country like "United States%";

select distinct country, trim(trailing "." from country)
from layoff_staging2
order by 1;


update layoff_staging2
set country = trim(trailing "." from country)
where country like "United States%";
```

---

### Step 5: Converting Date Column from Text to Date Type

Because the `date` column was imported as text, it was converted to MySQL’s `DATE` type using `STR_TO_DATE()`:

```sql
select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoff_staging2;


update layoff_staging2
set `date` = str_to_date(`date`,'%m/%d/%Y');
```

Then, the column was altered to enforce the `DATE` datatype:

```sql
select `date`
from layoff_staging2;

alter table layoff_staging2
modify column `date` date ;
```

---

### Step 6: Handling Null and Blank Values

#### 6.1 Identifying Nulls and Blanks

To find rows with null or blank values in critical columns like `industry`:

```sql
select *
from layoff_staging2
where total_laid_off is null
and percentage_laid_off is null;
```

#### 6.2 Populating Missing Industry Data by Self-Join

Rows with missing `industry` values were updated by joining on company and location to find corresponding non-null values:

```sql
select t1.industry, t2.industry
from layoff_staging2 t1
join layoff_staging2 t2
 on t1.company= t2.company
 and t1.location=t2.location
where t1.industry is null 
and t2.industry is not null;

update layoff_staging2 t1
join layoff_staging2 t2
 on t1.company= t2.company
set t1.industry = t2.industry
where (t1.industry is null or t1.industry="")
and t2.industry is not null;
```

First, blanks were converted to `NULL` for consistency:

```sql
update layoff_staging2
set industry = null
where industry="";
```

---

### Step 7: Removing Irrelevant Rows and Columns

Rows where both `total_laid_off` and `percentage_laid_off` are NULL were considered unreliable and deleted:

```sql
delete
from layoff_staging2
where total_laid_off is null
and percentage_laid_off is null
```

---
- **🏆Best Practices Followed:**
  - Maintained the original raw dataset intact by creating separate staging tables for cleaning operations, mimicking real-world ETL workflows.
  - Iterative, exploratory approach allowed troubleshooting and refinement of queries to handle edge cases and data anomalies.
  - Employed SQL scripting and procedural thinking to automate data cleaning tasks, paving the way for scalable and repeatable data preprocessing pipelines.
---
### 🎯 Project Outcome:
- Successfully transformed a raw, unstructured layoffs dataset into a clean, consistent, and reliable staging database.
- Enabled accurate and meaningful future **exploratory data analysis** by ensuring data integrity and standardization.
- Demonstrated practical, real-world techniques for cleaning data in MySQL, including handling duplicates, null values, inconsistent categories, and data type conversions.
- Developed a repeatable, professional workflow that preserves raw data and allows iterative cleaning without risk.
- Created a valuable portfolio project showcasing advanced SQL skills and data cleaning processes that are highly relevant to data engineering and analytics roles.
- Prepared the dataset for the next phase of analysis, where trends, patterns, and insights about layoffs across industries and geographies can be explored effectively.
---
### 📄Summary

This project involved importing raw data, creating staging environments, removing duplicates via advanced window functions, standardizing textual data, converting data types appropriately, imputing missing values through self-joins, and cleaning irrelevant data. The SQL code was carefully crafted to reflect real-world data cleaning challenges and best practices.

With the cleaned `layoffs_staging_2` table ready, the dataset is now primed for advanced exploratory data analysis and insightful visualizations, forming a strong foundation for data-driven decision-making.

---


This detailed project description, combined with exact SQL queries, provides a transparent, technical narrative of the data cleaning process, making it ideal for showcasing your SQL proficiency in a portfolio.

[![Connect with me on LinkedIn](https://img.shields.io/badge/Connect%20with%20me-LinkedIn-blue?logo=linkedin)](https://www.linkedin.com/in/md-nafis-al-zamee-a88a9024b)
