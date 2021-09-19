/****** Cleaning data using by SQL  ******/ 

-- Convert date and time format.

SELECT convert(date, SaleDate)
FROM Portfolio..nashvile_housing
ALTER TABLE nashvile_housing ADD SaleDate_convert date
UPDATE nashvile_housing
SET SaleDate_convert = convert(date, SaleDate) 

----------------------------------------------------------------------------------------------------

-- Fill null data Property Adress

SELECT a.ParcelID,
       a.PropertyAddress,
       b.ParcelID,
       b.PropertyAddress,
       isnull(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio..nashvile_housing a
JOIN Portfolio..nashvile_housing b ON a.ParcelID = b.ParcelID
AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio..nashvile_housing a
  JOIN Portfolio..nashvile_housing b 
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL 
  
----------------------------------------------------------------------------------------------------

-- Split out Address into Individual Columns (Address, City, State)
-- Method 1:

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
       SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 2, LEN(PropertyAddress)) AS City
FROM Portfolio..nashvile_housing

  ALTER TABLE nashvile_housing ADD Address_split nvarchar(255)
  ALTER TABLE nashvile_housing ADD City_split nvarchar(255)

  UPDATE nashvile_housing
  SET Address_split = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
  UPDATE nashvile_housing
  SET City_split = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+ 2, LEN(PropertyAddress)) 

-- Method 2 (OwnerAddress column):

  SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
         PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
         PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
  FROM Portfolio..nashvile_housing

  ALTER TABLE nashvile_housing ADD OwnerAddress_split nvarchar(255)
  ALTER TABLE nashvile_housing ADD OwnerCity_split nvarchar(255)
  ALTER TABLE nashvile_housing ADD OwnerState_split nvarchar(255)

  UPDATE nashvile_housing
  SET OwnerAddress_split = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
  UPDATE nashvile_housing
  SET OwnerCity_split = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
  UPDATE nashvile_housing
  SET OwnerState_split = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

  SELECT *
  FROM Portfolio..nashvile_housing 

----------------------------------------------------------------------------------------------------
  
-- Change 'Y', 'N' to 'Yes', 'No' in SoldAsVacant column. Using CASE WHEN

  SELECT SoldAsVacant,
         CASE
             WHEN SoldAsVacant = 'Y' THEN 'Yes'
             WHEN SoldAsVacant = 'N' THEN 'No'
             ELSE SoldAsVacant
         END
  FROM Portfolio..nashvile_housing

  UPDATE nashvile_housing
  SET SoldAsVacant = CASE
                         WHEN SoldAsVacant = 'Y' THEN 'Yes'
                         WHEN SoldAsVacant = 'N' THEN 'No'
                         ELSE SoldAsVacant
                     END

  SELECT distinct(SoldAsVacant),
         count(SoldAsVacant)
  FROM Portfolio..nashvile_housing
GROUP BY SoldAsVacant 

----------------------------------------------------------------------------------------------------

-- Remove Duplicates use CTE
 WITH tmp AS
  (SELECT *,
          ROW_NUMBER() OVER (PARTITION BY ParcelID,
                                          PropertyAddress,
                                          SalePrice,
                                          SaleDate,
                                          LegalReference
                             ORDER BY UniqueID) row_num
   FROM Portfolio..nashvile_housing

DELETE
FROM tmp
WHERE row_num > 1

----------------------------------------------------------------------------------------------------

-- Delete unused columns.

alter table nashvile_housing
drop column OwnerAddress, PropertyAddress, SaleDate