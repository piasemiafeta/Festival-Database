Festival Organisation Database
==============================

Welcome to our Festival Organisation Database. For this project we were instructed to create a database that would handle and store data referring to a series of festivals. It contains information about the festivals, the locations of them, the events that are planned for the festivals, the stages, the performances, the artists as well as the visitors, the tickets, a secondary resell queue and the ratings some visitors left. In this repository you will find three files except for the README, two install files and one load file. The load file contains the data for the database whereas the install files contain the schema. The differnce between the two install files is that one contains some indeces added at the end (These are included in the install2.sql).

## Directory Features
- MySQL was utilised for robust and scalable data storage.
- The data was generated partly with the usage of LLMs as well as Python scripts that generated dummy data.
- The database install scipts also include triggers to insure the integrity of the data.
- Xampp version 3.3 was utilized for the uploading of the database.


## Database Information
The database includes informantion for all festivals from 2015 up until 2026. The duration of the festivals is three days. The locantions in which it takes place span all around the globe. We insured that every stage in which an event takes place has all the appropriate equipment for a given festival and there are three stages per year. We have nine events per year (three for each stage) for which 200 tickets become available (In total 1800 tickets per year). The performances span to up to three per stage in one day. The staff is assigned to one specific stage per festival. Two thousand visitors were generated and randomly assigned tickets. Through a Python script used to generate reviews for the performances we insured a 50% participation of the total sold tickets. Reviews were generated only up until 2024 since this year's event and next year's haven't technically happened yet. 

## Thank you ^^
We are the contributors:
- Rafailia Petrou
- Giwrgos Mixelakis
- Eleni Rapanos Kokkiza