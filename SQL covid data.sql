-- Looking at total cases vs total deaths
-- Shows what percentage of deaths based on the total number of cases
SELECT Location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,2) AS DeathPercentage
FROM CovidDeaths
WHERE		total_cases > 0 
		AND total_deaths > 0
		AND location = 'France' 
		AND total_cases > total_deaths
		AND continent <> ''
ORDER BY 1,2


-- Looking at total cases vs population
-- Shows what percentage of population got covid
SELECT Location, date, population, total_cases,ROUND((total_cases/population)*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE		total_cases > 0 
		AND location = 'France' 
		AND continent <> ''
ORDER BY 1,2



-- Looking at Countries with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) AS HighestInfectionCount,ROUND(MAX((total_cases/population))*100,2) AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent <> ''
GROUP BY Location, Population 
ORDER BY 4 desc



-- Looking at Countries with highest death count 
SELECT Location, MAX(cast(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent <> ''
GROUP BY Location
ORDER BY 2 desc



-- Looking at Continent with highest death count 
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



-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS CumulativePeopleVaccinated
FROM CovidDeaths dea
INNER JOIN	CovidVaccinations vac
			ON	dea.location = vac.location
				AND dea.date = vac.date
WHERE		dea.continent <> '' 
ORDER BY 1,2,3



-- USE CTE
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



-- USE Temp Table
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
