/*

Cleaning Data in SQL Queries

*/

-- Select Database
USE PortfolioProject;

-- View NashvilleHousing Data
SELECT *
FROM PortfolioProject.NashvilleHousing;

------------------------------------------------------------------------------------------------------------------------
-- View SaleDate & SaleDateConverted
SELECT SaleDate, SaleDateConverted
FROM PortfolioProject.NashvilleHousing;

-- Covert SaleDate to standardize date Format
SELECT SaleDate, CONVERT(SaleDate, DATE)
FROM PortfolioProject.NashvilleHousing;

-- Update table 'NashvilleHousing
UPDATE NashvilleHousing
SET SaleDate = CONVERT(SaleDate, DATE);

-- Alternative approach. Introduce 'SaleDateConverted' column
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(SaleDate, DATE);

------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- View NashvilleHousing data ordered by ParcelID
SELECT *
FROM PortfolioProject.NashvilleHousing
WHERE NULLIF(PropertyAddress, '') IS NULL
ORDER BY ParcelID;

SELECT 
	PropA.ParcelID, 
    PropA.PropertyAddress, 
    PropB.ParcelID, 
    PropB.PropertyAddress,
    -- Return first non-NULL value from list of arguments
    COALESCE(NULLIF(PropA.PropertyAddress, ''), NULLIF(PropB.PropertyAddress, ''))
FROM PortfolioProject.NashvilleHousing PropA
JOIN PortfolioProject.NashvilleHousing PropB
	ON PropA.ParcelID = PropB.ParcelID 
    AND PropA.UniqueID <> PropB.UniqueID
WHERE NULLIF(PropA.PropertyAddress, '') IS NULL;

UPDATE PortfolioProject.NashvilleHousing PropA
JOIN PortfolioProject.NashvilleHousing PropB
	ON PropA.ParcelID = PropB.ParcelID 
    AND PropA.UniqueID <> PropB.UniqueID
SET PropA.PropertyAddress = COALESCE(NULLIF(PropA.PropertyAddress, ''), NULLIF(PropB.PropertyAddress, ''))
WHERE NULLIF(PropA.PropertyAddress, '') IS NULL;

--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)
-- View PropertyAddress
SELECT PropertyAddress
FROM PortfolioProject.NashvilleHousing;

-- Split PropertyAddress into two separate columns
-- SUBSTRING_INDEX(PropertyAddress, ',' , 1 ) extracts portion of PropertyAddress before 1st comma
-- SUBSTRING(PropertyAddress, LENGTH(SUBSTRING_INDEX(PropertyAddress, ',', 1)) + 2) extracts portion of PropertyAddress after 1st comma
-- TRIM() removes leading and trailing spaces 
SELECT
SUBSTRING_INDEX(PropertyAddress, ',' , 1 ) AS Address, 
TRIM(SUBSTRING(PropertyAddress, LENGTH(SUBSTRING_INDEX(PropertyAddress, ',', 1)) + 2)) AS City 
FROM PortfolioProject.NashvilleHousing;

-- Create 2 new columns for the split address (PropertySplitAddress & PropertySplitCity)
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',' , 1 );

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = TRIM(SUBSTRING(PropertyAddress, LENGTH(SUBSTRING_INDEX(PropertyAddress, ',', 1)) + 2));

-- View updated NashvilleHousing table
SELECT *
FROM PortfolioProject.NashvilleHousing;

-- View OwnerAddress
SELECT OwnerAddress
FROM PortfolioProject.NashvilleHousing;

-- Split POwnerAddress into three separate columns (Address, City, State)
SELECT
	SUBSTRING_INDEX(OwnerAddress, ',', 1) AS Address,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1)) AS City,
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1)) AS State
FROM PortfolioProject.NashvilleHousing;

-- Create column for Address
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

-- Create column for City
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1));

-- Create column for State
ALTER TABLE NashvilleHousing
ADD OwnerSplitState VARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', -1));

-- View updated NashvilleHousing table
SELECT *
FROM PortfolioProject.NashvilleHousing;

--------------------------------------------------------------------------------------------------------------------------

-- View entries in 'SoldAsVacant' column
SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM PortfolioProject.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY Count(SoldAsVacant);

-- Change Y and N to Yes and No in "Sold as Vacant" field using CASE ... WHEN
SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
	END
FROM PortfolioProject.NashvilleHousing;

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
						WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
					END;

-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

-- CTE Calculating row numbers for each row based on criteria within 'PARTITION BY'
-- 'ROW_NUMBER()' function assigns a unique sequential integer to each row within the partition
-- The partition is defined by the combination of columns: 'ParcelID', 'PropertyAddress', 'SalePrice', 'SaleDate', and 'LegalReference'
-- The rows are ordered by the 'UniqueID' column
-- The WHERE row_num > 1 condition filters out rows that have a row_num value of 1, 
-- leaving only rows with duplicate values according to the specified criteria
-- Result set is ordered by the PropertyAddress column

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY 
			ParcelID,
			PropertyAddress,
			SalePrice,
			SaleDate,
			LegalReference
		ORDER BY
			UniqueID
	) row_num
FROM PortfolioProject.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;


-- View updated table NashvilleHousing
SELECT *
FROM PortfolioProject.NashvilleHousing;

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns
ALTER TABLE PortfolioProject.NashvilleHousing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate;

-- View updated table 'NashvilleHousing
SELECT *
FROM PortfolioProject.NashvilleHousing;
