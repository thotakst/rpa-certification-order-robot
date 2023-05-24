*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images

Library             RPA.Browser.Selenium
Library             RPA.Tables
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get Orders
    FOR    ${order}    IN    @{orders}
        Run Keyword And Continue On Failure    Fill the form    ${order}
    END
    Create ZIP package from PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get Orders
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    overwrite=True
    ${table}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${table}

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Click Element    xpath=//div[@class='radio form-check']//input[@value='${order}[Body]']
    Input Text    //input[@class='form-control' and @type='number']    ${order}[Legs]
    Input Text    //input[@class='form-control' and @type='text']    ${order}[Address]
    Click Button    id:preview
    Click Button    id:order
    ${flag}=    Is Element Visible    //div[@class="alert alert-danger"]
    WHILE    ${flag}
        Click Button    id:order
        ${flag}=    Is Element Visible    //div[@class="alert alert-danger"]
    END
    ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
    ${screenshot}=    Take a screenshot of the robot    ${order}[Order number]
    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another
    Close the annoying modal

Close the annoying modal
    Click Button When Visible    xpath=//button[@class='btn btn-warning']

Store the receipt as a PDF file
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:receipt
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_file}=    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}pdfs${/}${row}.pdf
    RETURN    ${OUTPUT_DIR}${/}pdfs${/}${row}.pdf

Take a screenshot of the robot
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:robot-preview-image
    ${screenshot}=    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}images${/}${row}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}    append=${True}
    Close Pdf    ${pdf}

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}pdfs
    ...    ${zip_file_name}
