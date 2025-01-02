-- View the table that we are going to use
SELECT *
FROM Portfolioproject..CovidDeaths
ORDER BY 3,4


--Looking at total cases
SELECT location,date, total_cases,new_cases,total_deaths,population
FROM Portfolioproject..CovidDeaths
ORDER BY 1,2

--Looking at total cases vs total deaths
SELECT location,date, total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
FROM Portfolioproject..CovidDeaths
ORDER BY 1,2

--Looking at total cases vs population
-- Show what percentage of populatiion got covid
SELECT location,date, population,total_cases, (total_cases/population)*100 as populationpercentage
FROM Portfolioproject..CovidDeaths
WHERE location like '%India%'
ORDER BY 1,2

--looking at countries with highest infected population
SELECT location, population,MAX(total_cases) as highestinfected, MAX((total_cases/population))*100 as populationpercentage_infected
FROM Portfolioproject..CovidDeaths
--WHERE location like '%India%'
WHERE continent is NOT NULL
Group BY location,population
ORDER BY populationpercentage_infected desc

--showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths as INT)) as highestdeaths
FROM Portfolioproject..CovidDeaths
--WHERE location like '%India%'
WHERE continent is NOT NULL
Group BY location
ORDER BY highestdeaths desc

--break down by continents
SELECT continent, MAX(cast(total_deaths as INT)) as highestdeaths
FROM Portfolioproject..CovidDeaths
--WHERE location like '%India%'
WHERE continent is not NULL
Group BY continent
ORDER BY highestdeaths desc

--showing the continents by highest death count per population
SELECT continent,population, MAX(cast(total_deaths as INT)) as highestdeaths,MAX(cast(total_deaths as int)/population)*100 as highestdeath_perpopulation
FROM Portfolioproject..CovidDeaths
--WHERE location like '%India%'
WHERE continent is not NULL
Group BY continent,population
ORDER BY highestdeath_perpopulation desc

--for new cases and new deaths
Select SUM(new_cases )as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as percentdeaths
FROM Portfolioproject..CovidDeaths
Where continent is not null
--Group BY date
Order by percentdeaths desc

---to join deaths and vaccinations 
Select *
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
Order by 2,3

--looking for total population vs new vaccination
Select dea.location,dea.date,dea.population,vac.new_vaccinations
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
WHERE dea.location like '%India%'
Order by 2,3

--looking vaccine per continent
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent is not null
Order by 2,3

--when need to find vaccination done per population but direct use of % formula gives error!
--method 1 -> USE CTE
With PopvsVac(Continent,location,date,population,New_vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent is not null
--Order by 2,3
)
Select *,(RollingPeopleVaccinated/population)*100
From PopvsVac

--Method 2 making a TEMP table

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated(
continent varchar(225),
location varchar(225),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric )

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent is not null
--Order by 2,3

Select *,(RollingPeopleVaccinated/population)*100
From #PercentPopulationVaccinated


--creating view for later data visualization

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location,dea.date,dea.population,vac.new_vaccinations
, SUM(CONVERT(INT,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM Portfolioproject..CovidDeaths dea
JOIN Portfolioproject..CovidVaccinations$ vac ON dea.location=vac.location and dea.date=vac.date
WHERE dea.continent is not null
--Order by 2,3

Select *
From PercentPopulationVaccinated

/* Query for tableau */
--1
Select SUM(new_cases )as Total_cases, SUM(cast(new_deaths as int)) as Total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as percentdeaths
FROM Portfolioproject..CovidDeaths
Where continent is not null
--Group BY date
Order by percentdeaths desc

--2
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--3
SELECT location, population,MAX(total_cases) as highestinfected, MAX((total_cases/population))*100 as populationpercentage_infected
FROM Portfolioproject..CovidDeaths
--WHERE location like '%India%'
WHERE continent is NOT NULL
Group BY location,population
ORDER BY populationpercentage_infected desc

--4
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
Group by Location, Population, date
order by PercentPopulationInfected desc