/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by 1,2
	
	
-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE		total_cases > 0 
		AND total_deaths > 0
		AND location = 'France' 
		AND total_cases > total_deaths
		AND continent <> ''
ORDER BY 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
	
SELECT Location, date, population, total_cases,ROUND((total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE		total_cases > 0 
		AND location = 'France' 
		AND continent <> ''
ORDER BY 1,2



-- Countries with Highest Infection Rate compared to Population
	
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount,ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population 
ORDER BY 4 desc



-- Countries with Highest Death Count per Population
	
SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> ''
GROUP BY Location
ORDER BY 2 desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
	
SELECT location as Continent, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE	continent = '' AND iso_code NOT IN ('OWID_WRL', 'OWID_EUN', 'OWID_LIC', 'OWID_LMC', 'OWID_UMC', 'OWID_HIC')
GROUP BY location
ORDER BY 2 desc

SELECT iso_code, location FROM CovidDeaths 
where continent = ''
GROUP BY iso_code, location



--Global numbers
	
SELECT date, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeath, SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE	continent = '' 
		AND iso_code NOT IN ('OWID_WRL', 'OWID_EUN', 'OWID_LIC', 'OWID_LMC', 'OWID_UMC', 'OWID_HIC')
		AND new_cases > 0
		AND new_deaths > 0
GROUP BY date
ORDER BY 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
	
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativePeopleVaccinated
FROM CovidDeaths dea
INNER JOIN	CovidVaccinations vac
			ON	dea.location = vac.location
				AND dea.date = vac.date
WHERE		dea.continent <> '' 
ORDER BY 1,2,3



-- Using CTE to perform Calculation on Partition By in previous query
	
With PopVsVac (continent, location, date, population, New_vaccinations, CumulativePeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativePeopleVaccinated
FROM CovidDeaths dea
INNER JOIN	CovidVaccinations vac
			ON	dea.location = vac.location
				AND dea.date = vac.date
WHERE		dea.continent <> '' 
)
SELECT *, (CumulativePeopleVaccinated/population)*100 AS PercentageCumulVaccinated
FROM PopVsVac
WHERE location ='France'



-- Using Temp Table to perform Calculation on Partition By in previous query
	
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulativePeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativePeopleVaccinated
FROM CovidDeaths dea
INNER JOIN	CovidVaccinations vac
			ON	dea.location = vac.location
				AND dea.date = vac.date
WHERE		dea.continent <> '' 

SELECT *, (CumulativePeopleVaccinated/population)*100 AS PercentageCumulVaccinated
FROM #PercentPopulationVaccinated
WHERE location ='France'


-- Creating view to store data for later visualizations
	
CREATE View CountPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativePeopleVaccinated
FROM CovidDeaths dea
INNER JOIN	CovidVaccinations vac
			ON	dea.location = vac.location
				AND dea.date = vac.date
WHERE		dea.continent <> '' 

SELECT *
FROM CountPopulationVaccinated
