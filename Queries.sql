-- A quick look to our dataset
Select * from dataset

-- After realizing that our saledate column's data type is DateTime but there is no time information in our data, I would like to make it date data type. 
select SaleDate, cast(SaleDate as Date	)
from dataset

-- The code below for some reason doesn't work. So we need to find another method to do this.
Update dataset
Set SaleDate = cast(SaleDate as Date)

-- Here we are adding a another date column and giving it the saledate in a format we want.
Alter table dataset
Add SaleDateConverted date

Update dataset
Set SaleDateConverted = cast(SaleDate as Date)

-- Here we are going to split the propertyaddress into two. In the end we have the city information
-- sepeareted with comma. So it is useful that we have a constant delimter which is comma.

-- Quick explanation, With substring function, 
-- first argument is the string we want to work on
-- Second argument is the start point
-- Third argument is the position we want to go till.
-- Here we define CHARINDEX function which gives us the position of the argument we give in a given string.
-- In a nutshell, We have given the start positon and the position of the comma with the help of CHARINDEX function.
-- With first Substring we got the first part of the Property adress
-- With second part, the start position is no longer 1, it is now the position of the comma.
-- We know how to get the position of the comma with charindex function.
-- End position is the end of the string which is another words, length of the string. 
-- We have LEN() function for that and used it here. 
-- You might ask what is the -1 in the first substring and +1 in the second substring?
-- When we parse the string it goes until ',' inclusive but we don't want comma in our column anymore.
-- in order to avoid it, we just make -1 from the end position which we aquired with charindex function.
-- charindex function gives int value so we can implement mathmatical operations.
-- and in the second part +1 also has the same logic.
Select PropertyAddress, SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
						SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))
from dataset


-- Now we will add the 2 columns and update the null information with the information we just created.

-- Adding Tables
Alter table dataset
ADD SplitAddress Nvarchar(255)

Alter table dataset
ADD SplitCity Nvarchar(255)

-- Updating the null values with the values we just operated.
Update dataset
Set SplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1)


Update dataset
Set SplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1,LEN(PropertyAddress))

-- Checking everything is allright.
Select *
from dataset

-- Now we got seperated address values which is more handy.

-- Let's implemeted the same thing for owners address. 
-- Here we don't have just 2 information, we have 3 part, the new part is the state information.
-- It is going to be a bit more tricky.

-- Worked on a combination of Substring and charindex but I got an issue in the SecondPart. Even though the parameters are correct, 
-- I don't get the result I want to. It gives me the City and State together even though it should give just city. 
-- Anyway, We got another simple and very useful function, Parsname(). 
select OwnerAddress, SUBSTRING(OwnerAddress,1, CHARINDEX(',',OwnerAddress)-1) as FirstPart,
SUBSTRING(OwnerAddress, CHARINDEX(',',OwnerAddress)+1,CHARINDEX(', ',OwnerAddress,CHARINDEX(', ',OwnerAddress)+1)) as SecondPart,
Substring(OwnerAddress, CHARINDEX(',',OwnerAddress,CHARINDEX(',',OwnerAddress)+1)+1, len(OwnerAddress)) as ThirdPart
from dataset

-- Parsname, as its name implies, it parses the string and returns a value with the information of given sequence. 
-- One important feature of parsname is that it only parses the string whose delimeter is dot/period. 
-- In our case, we first need to replace the commas with periods.

Select PARSENAME(REPLACE(OwnerAddress, ',','.') , 3) FirstPart,
		PARSENAME(REPLACE(OwnerAddress, ',','.') , 2) SecondPart,
		PARSENAME(REPLACE(OwnerAddress, ',','.') , 1) Thirdpart
from dataset
-- Another weird feature of parsname is that the position argument you need to give as a second argument is backwards. 

-- That must be it. In the first part actually it is more complex but it gives the flavor of substring and Charindex. 
-- Parsname is a such a gamechanger function here. 

-- Low let's again create those 3 columns and give their values.

Alter table dataset
Add OwnerSplitAddress Nvarchar(255)

Alter table dataset
Add OwnerSplitCity Nvarchar(255)

Alter table dataset
Add OwnerSplitState Nvarchar(255)


Update dataset
Set OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') , 3)


Update dataset
Set OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.') , 2)


Update dataset
Set OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') , 1)

-- Let's check them 

select * from dataset


-- We got some missing address, let's look at them if we can populate. 
select * 
from dataset
where PropertyAddress is null
-- We can populate because of ParcelID. 
-- Because propertyaddress doesn't change as long as the property exists. 
-- When the ParcelID's of 2 property address are equal, their property address are also equal when we look at the dataset.
-- So, let's work on it.

-- We made self-join because we are interested in comparing two values in one table.

Select d1.UniqueID,d2.UniqueID, d1.ParcelID,d2.ParcelID, d1.PropertyAddress, d2.PropertyAddress, ISNULL(d1.PropertyAddress, d2.PropertyAddress)
from dataset d1 
join dataset d2
on d1.ParcelID = d2.ParcelID and d1.[UniqueID ] <> d2.[UniqueID ]
where d1.PropertyAddress is null -- and d2.PropertyAddress is not null.

-- In order not to get the same row to same row, you can do it in the on section by saying d1.[UniqueID ] <> d2.[UniqueID ]
-- Or you could do by saying "and d2.PropertyAddress is not null" either way it is working.
-- Here we got 35 rows which we can populate address, so let's do it.

-- Here, we use Update statement with a join statement. Because we are doing so, we should indicated the allias name of the tables in the update statement. 
Update d1
Set d1.PropertyAddress = ISNULL(d1.PropertyAddress, d2.PropertyAddress)
from dataset d1 
join dataset d2
on d1.ParcelID = d2.ParcelID and d1.[UniqueID ] <> d2.[UniqueID ]
where d1.PropertyAddress is null

-- Let's look at the distinct value of SoldAsVacant column.
-- We are getting 4 of them "N","Yes","Y","No" 

Select distinct SoldAsVacant , Count(SoldAsVacant) count from dataset
group by SoldAsVacant
order by count






-- Because the count of Yes and No s are greater than the Y and N, let's convert the Y and N s into Yes and No s. 

Select SoldAsVacant , Case when SoldAsVacant = 'Y' then 'Yes'
							when SoldAsVacant = 'N' then 'No'
						Else SoldAsVacant
						End 
from dataset

-- With this Case statement, we are good to go.

Update dataset
Set SoldAsVacant = Case when SoldAsVacant = 'Y' then 'Yes'
						when SoldAsVacant = 'N' then 'No'
					Else SoldAsVacant
					End



--- Let's Remove the Duplicates.

Select * from dataset

-- Basically I will assume that if two or more column's SaleDate,SalePrice ParcelID, PropertyAddress and finally LegalReference are same, THey are duplicate.

-- Row_Number function gives us sequence of numbers from (1 to infinity) with regard to partition by. 
-- In our case, when those columns described above are same, the second value is going to get 2 and third is going to get 3. 
-- Because we can't use window functions in where statement. We simply created a CTE and go from there with a where clause. 
WITH Duplicates AS (
Select *, ROW_NUMBER() over(partition by SaleDate,
										SalePrice,
										ParcelID,
										PropertyAddress,
										LegalReference
										order by UniqueID) as ro
from dataset

)
select * from Duplicates
where ro > 1

-- Let'S delet them.
WITH Duplicates AS (
Select *, ROW_NUMBER() over(partition by SaleDate,
										SalePrice,
										ParcelID,
										PropertyAddress,
										LegalReference
										order by UniqueID) as ro
from dataset

)

Delete 
from Duplicates
where ro > 1

-- After deleting every duplicates, We are good to go right now. 

-- That's it for now, Keep creating, keep learning, keep fighting.