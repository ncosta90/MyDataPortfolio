/*
Covid 19 Data Exploration 
Skills used: Creating Tables,Copyng data,Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- TABLES CREATION

CREATE TABLE covid_deaths (
	iso_code varchar,
	continent varchar, 
	location varchar, 
	date timestamp,
	population float,
	total_cases float, 
	new_cases float,
	new_cases_smoothed float,
	total_deaths float,
	new_deaths float,
	new_deaths_smoothed float,
	total_cases_per_million float,
	new_cases_per_million float,
	new_cases_smoothed_per_million float,
	total_deaths_per_million float, 
	new_deaths_per_million float,
	new_deaths_smoothed_per_million float,
	reproduction_rate float, 
	icu_patients float,
	icu_patients_per_million float,
	hosp_patients float,
	hosp_patients_per_million float,
	weekly_icu_admissions float,
	weekly_icu_admissions_per_million float,
	weekly_hosp_admissions float,
	weekly_hosp_admissions_per_million float
)

CREATE TABLE covid_vaccinations (
	iso_code varchar,
	continent varchar,
	location varchar,
	date timestamp,
	new_tests float,
	total_tests float,
	total_tests_per_thousand float,
	new_tests_per_thousand float,
	new_tests_smoothed float,
	new_tests_smoothed_per_thousand float,
	positive_rate float,
	tests_per_case float,
	tests_units varchar,
	total_vaccinations float,
	people_vaccinated float,
	people_fully_vaccinated float,
	new_vaccinations float,
	new_vaccinations_smoothed float,
	total_vaccinations_per_hundred float,
	people_vaccinated_per_hundred float,
	people_fully_vaccinated_per_hundred float,
	new_vaccinations_smoothed_per_million float,
	stringency_index float,
	population_density float,
	median_age float,
	aged_65_older float,
	aged_70_older float,
	gdp_per_capita float,
	extreme_poverty float,
	cardiovasc_death_rate float,
	diabetes_prevalence float,
	female_smokers float,
	male_smokers float,
	handwashing_facilities float,
	hospital_beds_per_thousand float,
	life_expectancy float,
	human_development_index float
)

-- COPYING THE CSV DATA INTO THE NEW TABLES

COPY covid_deaths FROM '/Users/Shared/CovidDeaths.csv' DELIMITER ',' CSV HEADER;
COPY covid_vaccinations FROM '/Users/Shared/CovidVaccinations.csv' DELIMITER ',' CSV HEADER;

-- COUNT OF UNIQUE RECORDS --> COVID_DEATHS --> 85171

SELECT COUNT(*)
FROM 
(
	SELECT DISTINCT *
	FROM covid_deaths

) AS TMP

-- COUNT OF UNIQUE RECORDS --> COVID_VACCINATIONS --> 85171

SELECT COUNT(*)
FROM 
(
	SELECT DISTINCT *
	FROM covid_vaccinations

) AS TMP

-- 

SELECT *
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_deaths
WHERE continent IS NOT null 
ORDER BY continent, location, date

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE location LIKE '%Argen%'
ORDER BY date

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT location, date, Population, total_cases,  (total_cases/population)*100 AS PercentPopulationInfected
FROM covid_deaths
WHERE (location LIKE '%Argen%') AND (total_cases IS NOT null)
ORDER BY date

-- Countries with Highest Infection Rate compared to Population

SELECT location, Population, MAX(total_cases) AS HighestInfectionCount,  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY location, Population
HAVING MAX(total_cases/population) IS NOT null
ORDER BY PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT location, MAX(Total_deaths) AS TotalDeathCount
--SELECT location, MAX(CAST(Total_deaths AS integer)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY location
HAVING MAX(Total_deaths) IS NOT null
ORDER BY TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT continent, MAX(Total_deaths) AS TotalDeathCount
--SELECT continent, MAX(CAST(Total_deaths as integer)) AS TotalDeathCount
FROM covid_deaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 AS DeathPercentage
FROM covid_deaths
WHERE continent IS NOT null

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, CumSum_PeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumSum_PeopleVaccinated
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null 
)
SELECT *, (CumSum_PeopleVaccinated/population)*100 AS Percentage_People_Vaccinated
From PopvsVac

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS CumSum_PeopleVaccinated
FROM covid_deaths AS dea
JOIN covid_vaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *
FROM PercentPopulationVaccinated

-----------------------------------
-----------------------------------

-- SOURCE OF PROJECT: https://www.youtube.com/watch?v=qfyynHBFOsM&t=296s -- Alex The Analyst