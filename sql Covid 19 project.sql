Select * From
 [sql project]..death$
 order by 3, 4 -- sorted by the 3rd column first and then 4th column

 --Select * From 
 --[sql project]..vaccination$
 --order by 3, 4

 -- Select the Data to be used
 Select location, date, total_cases, new_cases, total_deaths, population
 From [sql project]..death$
 order by 1, 2 --based off the location abd the date

 -- looking at the total cases vs total deaths
 -- shows the likelihood of dying if you vontact covid in your country
 SELECT 
    CAST(total_deaths AS FLOAT) / total_cases AS result
FROM 
    [sql project]..death$


 Select location, date, total_cases,total_deaths, CAST(total_deaths as float) / total_cases * 100 as deathpercentage
 From [sql project]..death$ --total_death was a nvarchar column so i employed cast to change it to float
 WHERE location = 'Afghanistan' 
 order by 1, 2   -- as of recent they were 233472 cases and 7985 deaths which is 3 percent       
                 -- so you have a 4 percent chance of dying if you get diagnosed

Select location, date, total_cases,total_deaths, CAST(total_deaths as float) / total_cases * 100 as deathpercentage
 From [sql project]..death$ 
 WHERE location like '%states%' and  total_cases like '1_______'
 order by 1,2

 Select location, date, total_cases,total_deaths, CAST(total_deaths as float) / total_cases * 100 as deathpercentage
 From [sql project]..death$ 
 WHERE location like '%nigeria%' and  date like '%2024%'
 order by 1,2 -- Which means as of 2024 if you have covid, youll be at a 1 percent chance of dying

 --Looking at the total cases vs population
 --shows what percentage of the population has gotten covid

 Select location, date, total_cases, population, (total_cases/ population) * 100 as deathpercentage
 From [sql project]..death$ 
 WHERE location like '%states%'
 order by 1,2 

 with CTE_death as 
 (Select location, date, total_cases, population, (total_cases/ population) * 100 as deathpercentage
 From [sql project]..death$ 
 WHERE location like '%states%')-- you cant use order by in CTE expression
 Select * FROM CTE_death WHERE deathpercentage > 20
 order by 1,2 -- you can apply order by outside

 --looking at countries with higher infection rates compared to populations
 Select location, MAX(total_cases) as Highestinfectioncount, population, MAX(total_cases/ population) * 100 as populationinfected
 From [sql project]..death$ 
 --WHERE location like '%states%'
 group by population, location
 order by populationinfected desc

 with cte_population as
 (Select location, MAX(total_cases) as Highestinfectioncount, population, MAX(total_cases/ population) * 100 as populationinfected
 From [sql project]..death$ 
 group by population, location)
 Select * from cte_population
 where location = 'Nigeria'

 --showing the countries with highest death count
  Select location, MAX(total_deaths) as Totaldeathcount
 From [sql project]..death$ 
 group by location
 order by Totaldeathcount desc --we are not getting the accurate result
 -- because of a datatype issue iwth total deaths being on nvarchar format
 -- so we apply cast and change it to int or float

 Select location, MAX(cast(total_deaths as float)) as Totaldeathcount
 From [sql project]..death$ 
 group by location
 order by Totaldeathcount desc-- we are having an issue with the location
 -- grouping by world and income

 Select * From
 [sql project]..death$
  where continent is null
 order by 3, 4 
 -- seems continet and location swap data values when continent is null

 Select location, MAX(cast(total_deaths as float)) as Totaldeathcount
 From [sql project]..death$ 
 where continent is not null
 group by location
 order by Totaldeathcount desc

  Select location, MAX(cast(total_deaths as float)) as Totaldeathcount
 From [sql project]..death$ 
 where continent is null
 group by location
 order by Totaldeathcount desc


 --LETS BREAK THINGS DOWN BY CONTINENT
 --showing the continent with highest death count

  Select continent, MAX(cast(total_deaths as float)) as Totaldeathcount
 From [sql project]..death$ 
 where continent is not null
 group by continent
 order by Totaldeathcount desc

 --	GLOBAL NUMBERS
Select  date,  SUM(new_cases), SUM(cast(new_deaths as float))--total_cases,total_deaths, CAST(total_deaths as float) / total_cases * 100 as deathpercentage
 From [sql project]..death$ 
 where continent is not null
 group by date
 order by 1,2 --this will give us on each day the total new cases across the world

 Select SUM(new_cases) as total_case, SUM(cast(new_deaths as int)) as total_death, SUM(cast(new_deaths as int))/ SUM(new_cases)
 * 100 as deathpercentage
 From [sql project]..death$ 
 where continent is not null
 --group by date
 order by 1,2 --so across the world we are looking at a death percentage less than 1


 -- Looking at total population vs vaccination
 Select * From 
 [sql project]..death$ as dae
 join [sql project]..vaccination$ as vac 
 on dae.location = vac.location
 and dae.date = vac.date

 Select  dae.continent, dae.location, dae.date, dae.population, vac.new_vaccinations From 
 [sql project]..death$ as dae                                   --new vaccinations per day
 join [sql project]..vaccination$ as vac 
    On dae.location = vac.location
    and dae.date = vac.date
where dae.continent is not null
order by 2, 3

With PopsVac as(
 Select  dae.continent, dae.location, dae.date, dae.population, vac.new_vaccinations
 , SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dae.location Order by dae.location,
 dae.Date) as RollingPeopleVaccinated From
 [sql project]..death$ as dae   -- partition by location because everytime it gets to a new location                                 
 join [sql project]..vaccination$ as vac  -- we want the count to start over, so it did the sum of every
    On dae.location = vac.location     -- new_vaccination by that location
    and dae.date = vac.date
where dae.continent is not null
--order by 2, 3
)
Select * , (RollingPeopleVaccinated/population)*100
From PopsVac 

--USING A TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dae.continent, dae.location, dae.date, dae.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dae.Location Order by dae.location, dae.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [sql project]..death$ as dae
Join [sql project]..vaccination$ vac
	On dae.location = vac.location
	and dae.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Create View to store data for later visualization

Drop View PercentPopulationVaccinated

Create View PercentPopulationVaccinated as
Select dae.continent, dae.location, dae.date, dae.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dae.Location Order by dae.location, dae.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [sql project]..death$ as dae
Join [sql project]..vaccination$ vac
	On dae.location = vac.location
	and dae.date = vac.date
where dae.continent is not null 
--order by 2,3 -
--check sql_project schema to access view

Select * From PercentPopulationVaccinated