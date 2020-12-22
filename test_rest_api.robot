*** Settings ***
Library  OperatingSystem
Library  Process
Library  DatabaseLibrary
Library  ./json_parser.py
Suite Setup    Start setup
Suite Teardown  Teardown setup

*** Variables ***
${json_path}  data.json
${post_counter}  0

*** Test Cases ***
Test wamp is booted  
    Wait Until Keyword Succeeds	 40s  5s  Is wamp booted

Create table
    Query	CREATE TABLE airports_europe (`id` integer, `Country` varchar(100), `Airport` varchar(200), `City` varchar(200), `Passengers` integer)
    Table Must Exist	airports_europe 
    Row Count Is Equal To X  SELECT * FROM airports_europe  0

Test POST
    ${json_dict}=  json_to_dict  ${json_path}
    Log  ${json_dict['POST']}
    FOR    ${airport}     IN      @{json_dict['POST']}
        ${post_counter}  Evaluate    ${post_counter} + 1
        Query  INSERT INTO `airports_europe` (`id`, `Country`, `Airport`, `City`, `Passengers`) VALUES (${airport['id']},'${airport['Country']}','${airport['Airport']}','${airport['City']}',${airport['Passengers']})
    END
    ${rowCount}	Row Count	SELECT * FROM airports_europe
    Should Be Equal As Integers  ${post_counter}  ${rowCount}

Test GET
    ${table}	 Query	SELECT * FROM airports_europe	
    Log Many	@{table}

Test PUT
    ${json_dict}=  json_to_dict  ${json_path}
    Log  ${json_dict['PUT']}
    Query  UPDATE airports_europe SET `Passengers`= ${json_dict['PUT']['Passengers']} WHERE id = ${json_dict['PUT']['id']}
    ${check_value}  Query  SELECT Passengers FROM airports_europe WHERE id = ${json_dict['PUT']['id']}
    Should Be Equal As Integers  ${check_value[0][0]}  ${json_dict['PUT']['Passengers']}
    ${table}	 Query	SELECT * FROM airports_europe	
    Log Many	@{table}

Test DELETE
    ${json_dict}=  json_to_dict  ${json_path}
    Log  ${json_dict['DELETE']}
    Query  DELETE FROM airports_europe WHERE id IN (${json_dict['DELETE']['id'][0]},${json_dict['DELETE']['id'][1]})
    Row Count Is Equal To X  SELECT * FROM airports_europe  1
    ${table}	 Query	SELECT * FROM airports_europe	
    Log Many	@{table}
    
Drop table
    Query  DROP TABLE airports_europe
    Run Keyword And Expect Error	Table 'airports_europe' does not exist in the db	 Table Must Exist  airports_europe

*** Keywords ***
Start setup
    Start Process  wamp.bat

Is wamp booted
    Connect To Database  dbConfigFile=db.cfg

Teardown setup
    Disconnect From Database

