-- Data Cleaning
-- 1.Deleting Duplicates
-- 2.Standardize the data
-- 3.removing Null & Blank values
-- 4.remove any columns or rows


-- Deleting Duplicates

select *
from layoffs;

create table layoff_staging
like layoffs;
 select * 
 from layoff_staging;
 insert into layoff_staging
 select *
 from layoffs;
 
 select*
 from layoff_staging;
 
 
 select * , 
 Row_number() over(partition by company, location, industry,total_laid_off,'date',stage,country,funds_raised_millions) as row_num
 from layoff_staging;
 
 with duplicate_cte as
	(select * , 
 Row_number()
 over(partition by company, location, industry,total_laid_off,'date',stage,country,funds_raised_millions) as row_num
 from layoff_staging )
 
 select * from duplicate_cte where row_num>1;
 
 select*
 from layoff_staging
 where company = "Zappos";
 
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
 
 Delete 
from layoff_staging2
where row_num>1;


SET SQL_SAFE_UPDATES = 0;
DELETE FROM layoff_staging2 WHERE row_num > 1;
SET SQL_SAFE_UPDATES = 1; -- Re-enable safe updates after execution

-- Standardizing data

select company, 
 (trim(company))
from layoff_staging2;

update layoff_staging2
set company =trim(company);

select distinct industry 
from layoff_staging2
order by 1;

select *
from layoff_staging2
where industry like "crypto%";

update layoff_staging2
set industry = "Crypto"
where industry like "crypto%";

select distinct location
from layoff_staging2
order by 1;

select distinct country 
from layoff_staging2
order by 1;


select *
from layoff_staging2
where country like "United States%";

select distinct country, trim(trailing "." from country)
from layoff_staging2
order by 1;


update layoff_staging2
set country = trim(trailing "." from country)
where country like "United States%";

select `date`,
str_to_date(`date`,'%m/%d/%Y')
from layoff_staging2;


update layoff_staging2
set `date` = str_to_date(`date`,'%m/%d/%Y');

select `date`
from layoff_staging2;

alter table layoff_staging2
modify column `date` date ;


-- removing Null & Blank values

select *
from layoff_staging2
where total_laid_off is null
and percentage_laid_off is null;

select distinct industry
from layoff_staging2;

update layoff_staging2
set industry = null
where industry="";

select *
from layoff_staging2
where industry is null 
or industry = "";

select *
from layoff_staging2
where company like "Ball%";

select *
from layoff_staging2;


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


delete
from layoff_staging2
where total_laid_off is null
and percentage_laid_off is null;

-- remove any columns or rows
select *
from layoff_staging2;


alter table layoff_staging2
drop column row_num;
