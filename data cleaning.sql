SELECT TOP (1000) [UniqueID ]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [sql project].[dbo].[nashville]

Select * From [sql project]..nashville

--Standardize Date Format
Select SaleDate, CONVERT(Date,SaleDate)
From [sql project]..nashville

ALTER TABLE [sql project]..nashville
Add SaleDateConverted Date;

Update [sql project]..nashville
SET SaleDateConverted =  CONVERT(Date,SaleDate)

Select SaleDateConverted, CONVERT(Date,SaleDate)
From [sql project]..nashville

Select * From [sql project]..nashville

--Populate Property Address data
Select PropertyAddress
From [sql project]..nashville
Where PropertyAddress is NULL

Select *
From [sql project]..nashville
Where PropertyAddress is NULL
-- take note that most of the time Property Address is constant
-- Lets do more research on the data
-- noticed that identical ParcelID had thesame property address

Select *
From [sql project]..nashville
order by 2--ParcelID
--if this parcelId has an address and this parcelid does not have an address
-- lets populate it with this address thats already populated cause we know 
-- these are going to be thesame


Select *
From [sql project]..nashville as a
JOIN [sql project]..nashville as b
 on a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ] --since unique id is unique '<>' not equals to
                                     --  can be used to distinguish the rows from each other
									 -- if two parcelid rows are identical and the uniqueid is
									 -- different we want to populate the propertyaddress row that
									 --is null with the address of one of the identical parcelID
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From [sql project]..nashville as a     --this isnull is replacing the null property address with b.propertyaddress
JOIN [sql project]..nashville as b
 on a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ] 
 where a.PropertyAddress is NULL

 Update a
 SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
 From [sql project]..nashville as a   
JOIN [sql project]..nashville as b
 on a.ParcelID = b.ParcelID
 AND a.[UniqueID ] <> b.[UniqueID ] 
 where a.PropertyAddress is NULL

 --Breaking out address into individual columns (address, city, state)

 Select PropertyAddress
From [sql project]..nashville

 SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)) as Address
 From  [sql project]..nashville --	CHARINDEX is seraching for a specific value
                                -- starts at the first value and returns until the ','
  			  			        -- the ',' is at a position	 so to get  rid of it 
								-- you return the value to end at the index before the
								-- position of the ',' 
 SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) as Address,
 SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) as Address
 From  [sql project]..nashville -- the second substring starts at the index after the ',' and
                                 -- ends at the index representing the length of the value


ALTER TABLE [sql project]..nashville
Add PropertySplitAddress Nvarchar(255);

Update [sql project]..nashville
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1)


ALTER TABLE [sql project]..nashville
Add PropertySplitCity Nvarchar(255);

Update [sql project]..nashville
SET PropertySplitCity =  SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))

Select *
From [sql project]..nashville


Select OwnerAddress
From [sql project]..nashville --lets split without substrring

Select PARSENAME(OwnerAddress,1)
From [sql project]..nashville
--returns thesame value because parsename only looks for periods '.'
--So best thing to do is replace those commas with periods
-- PARSE also seperates values backwards

Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
From [sql project]..nashville
-- or better i go
Select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From [sql project]..nashville


ALTER TABLE [sql project]..nashville
Add OwnerSplitAddress Nvarchar(255);

Update [sql project]..nashville
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)


ALTER TABLE [sql project]..nashville
Add OwnerSplitCity Nvarchar(255);

Update [sql project]..nashville
SET OwnerSplitCity =  PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE [sql project]..nashville
Add OwnerSplitState Nvarchar(255);

Update [sql project]..nashville
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

Select *
From [sql project]..nashville

--Change Y and N to Yes and No in 'Sold in Vacant' field

Select Distinct(SoldAsVacant), count(SoldAsVacant)
From [sql project]..nashville
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From [sql project]..nashville

Update [sql project]..nashville
SET SoldAsVacant =  CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From [sql project]..nashville

--Remove Duplicates, duplicate rows
-- WE need to partition it by something that is unique to each row
-- duplicate are rows that are identical in values on every column to another row
WITH Row_numCTE AS(
Select *,
 ROW_NUMBER() OVER(
 PARTITION BY ParcelID,
              PropertyAddress,
			  SalePrice,
			  LegalReference
			  ORDER BY
			    UniqueID
				) as row_num
From [sql project]..nashville
)
DELETE
From row_numcte
where row_num > 1
--Order by PropertyAddress

-- duplicate are rows that are identical in values on every column to another row
WITH Row_numCTE AS(
Select *,
 ROW_NUMBER() OVER(
 PARTITION BY ParcelID,
              PropertyAddress,
			  SalePrice,
			  LegalReference
			  ORDER BY
			    UniqueID
				) as row_num
From [sql project]..nashville
)
SELECT *
From row_numcte
where row_num > 1

--Delete Unsused Columns

Select * From [sql project]..nashville

ALTER TABLE [sql project]..nashville
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress,SaleDate

--the columns we created are much more useable, much more friendly,

--Remove null values
Select * From [sql project]..nashville
Where OwnerName is NOT NULL;

DELETE FROM [sql project]..nashville
Where OwnerName is  NULL;