*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive


*** Variables ***
${SCREENSHOT_OUTPUT_DIR}    ${OUTPUT_DIR}${/}screenshots${/}
${RECEIPT_OUTPUT_DIR}       ${OUTPUT_DIR}${/}receipts${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}    Get orders
    Process orders    ${orders}
    Create ZIP package of receipts


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    # Close the cookie popup
    Click Button    css:.btn-dark

Get orders
    # Download the csv file from https://robotsparebinindustries.com/orders.csv
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    target_file=${OUTPUT_DIR}${/}orders.csv
    ...    overwrite=${True}
    ${orders}    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv
    RETURN    ${orders}

Process orders
    [Arguments]    ${orders}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Wait Until Keyword Succeeds    5x    5s    Process Single Order    ${order}
        ${pdf}    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}    Take a screenshot of the robot    ${order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Next order
    END

Process single order
    [Arguments]    ${order}
    Log    ${order}
    # Fill in Head drop-down
    Select From List By Value    head    ${order}[Head]
    # Fill in Body radio group
    Select Radio Button    body    ${order}[Body]
    # Fill in part number for the legs
    Input Text    css:input[placeholder$="legs"]    ${order}[Legs]
    # Fill in Shipping Address
    Input Text    address    ${order}[Address]
    # Preview the Robot
    Click Button    preview
    # Submit the Order and handle error
    Click Button    order
    Assert order submitted

Assert order submitted
    Wait Until Page Contains Element    css:.alert-success    timeout=2s

Next order
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Wait Until Element Is Visible    receipt
    ${receipt}    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt}    ${RECEIPT_OUTPUT_DIR}${orderNumber}.pdf
    RETURN    ${RECEIPT_OUTPUT_DIR}${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    Screenshot    robot-preview-image    ${SCREENSHOT_OUTPUT_DIR}${orderNumber}.png
    RETURN    ${SCREENSHOT_OUTPUT_DIR}${orderNumber}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Log    ${screenshot}
    Log    ${pdf}
    ${files}    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}

Create ZIP package of receipts
    ${zip_file_path}    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip    ${RECEIPT_OUTPUT_DIR}    ${zip_file_path}
