*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Robocorp.Vault
Library             RPA.HTTP
Library             RPA.JavaAccessBridge
Library             RPA.Tables
Library             RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.Robocorp.Vault

*** Variables ***
${PDF_TEMP_OUTPUT_DIRECTORY}=       ${CURDIR}${/}temp

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Get Orders
    Create ZIP package from PDF files
    [Teardown]    Cleanup temporary PDF directory
    Log out and close the browser


*** Keywords ***
Open the robot order website
    ${secret}=    Get Secret    robotsparebin
    Open Available Browser    https://robotsparebinindustries.com/
    Maximize Browser Window
    Input Text    username    ${secret}[username]
    Input Password    password    ${secret}[password]
    Submit Form
    Wait Until Page Contains Element    css:#root > header > div > ul > li:nth-child(2) > a
    RPA.Browser.Selenium.Click Element    css:#root > header > div > ul > li:nth-child(2) > a

Close the annoying modal
    Click Button    css:#root > div > div.modal > div > div > div > div > div > button.btn.btn-dark

Get Orders
    Set up directories
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${robot}=    Read table from CSV    orders.csv    header=true
    Log    Found columns: ${robot.columns}
    FOR    ${robot_part}    IN    @{robot}
        Close the annoying modal
        Fill the form    ${robot_part}
    END
    Close the annoying modal

Log out and close the browser
    Wait Until Element Is Not Visible    Log out
    Click Button    Log out
    Close Browser

Fill the form
    [Arguments]    ${robot_part}
    Select From List By Value    css:#head    ${robot_part}[Head]
    Select Radio Button    body    ${robot_part}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${robot_part}[Legs]
    Input Text    css:#address    ${robot_part}[Address]
    Wait Until Keyword Succeeds    5x    1s    Click Button    css:#order
    Wait Until Keyword Succeeds    5x    1s    CreaPDF    ${robot_part}


Store the receipt as a PDF file
    [Arguments]    ${OrderNumber}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}receipt_${OrderNumber}.pdf    overwrite=True
    RETURN    receipt_${OrderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${OrderNumber}
    ${screenshotRobot}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_preview_${OrderNumber}.png
    RETURN    ${screenshotRobot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshotPNG}    ${filepdf}    ${OrderNumber}
    Open Pdf    ${OUTPUT_DIR}${/}${filepdf}
    ${robotPNG}=    Create List    ${screenshotPNG}
    ...    ${OUTPUT_DIR}${/}${filepdf}
    Add Files To Pdf    ${robotPNG}    ${PDF_TEMP_OUTPUT_DIRECTORY}${/}robot_${OrderNumber}.pdf
    Close Pdf    ${OUTPUT_DIR}${/}${filepdf}

Set up directories
    Create Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${PDF_TEMP_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}

Cleanup temporary PDF directory
    Remove Directory    ${PDF_TEMP_OUTPUT_DIRECTORY}    True

CreaPDF
    [Arguments]    ${robot_part}
       TRY
        ${pdf}=    Store the receipt as a PDF file    ${robot_part}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${robot_part}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${robot_part}[Order number]
        Wait Until Keyword Succeeds    5x    1s    Click Button    css:#order-another
    EXCEPT
        Wait Until Keyword Succeeds    5x    1s    Click Button    css:#order
            ${pdf}=    Store the receipt as a PDF file    ${robot_part}[Order number]
            ${screenshot}=    Take a screenshot of the robot    ${robot_part}[Order number]
            Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}    ${robot_part}[Order number]
            Wait Until Keyword Succeeds    5x    1s    Click Button    css:#order-another
        END
