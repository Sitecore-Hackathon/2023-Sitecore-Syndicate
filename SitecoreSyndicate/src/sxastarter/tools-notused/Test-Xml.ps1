function Test-Xml {
    <#
        .SYNOPSIS
        The Test-Xml cmdlet test an XML File for errors.
        .DESCRIPTION
        You should give the path to the XML file as an input an the cmdlet response with an object with next properties:
        Path: The full path to the given XML file to test.
        ValidXmlFile: A boolean value indication if it is a valid XML file.
        Error: Description of the error in case it exists.
        .LINK
        https://github.com/josuemb/HumanTechSolutions.PowerShell.XmlUtils
        .EXAMPLE
        Test-Xml -Path "c:\temp\myxmlfile.xml"
        Test the file: "c:\temp\myxmlfile.xml"
        .EXAMPLE
        Test-Xml -FullName "c:\temp\myxmlfile.xml"
        Test the file: "c:\temp\myxmlfile.xml"
        .EXAMPLE
        Test-Xml "c:\temp\myxmlfile.xml"
        Test the file: "c:\temp\myxmlfile.xml"
        .EXAMPLE
        Get-ChildItem -Path "C:\temp\" -Filter "*.xml" | ForEach-Object { Test-Xml $_.FullName }
        Test all xml files with an .xml extension in path: "c:\temp\"
    #>
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $false,
            Position = 0,
            HelpMessage = "Enter the XML file path"
        )]
        [ValidateScript({ if ($_) { Test-Path $_ } })]
        [Alias("FullName")]
        [string]$Path,
        [Alias("Extended")]
        [switch]$ExtendedProperties
    )
    BEGIN {
        #Initialize control variables
        $error = ""
        $validXmlFile = $true
        #Object for returning results
        $xmlValidationObj = New-Object -TypeName psobject
        Set-Variable "CONST_PATH" -Value "Path" -Option Constant
        Set-Variable "CONST_IS_VALID" -Value "ValidXmlFile" -Option Constant
        Set-Variable "CONST_ERROR" -Value "Error" -Option Constant
        Write-Debug "Creating object for default validation settings..."
        #XML validation settings
        $settings = New-Object System.Xml.XmlReaderSettings
        Write-Verbose "Setting validation type..."
        $settings.ValidationType = [System.Xml.ValidationType]::Schema
        Write-Verbose "Setting default validation flags..."
        Write-Verbose "Stablishing default validation flags..."
        #Set default validation flags
        $settings.ValidationFlags =
        [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessInlineSchema -bor
        [System.Xml.Schema.XmlSchemaValidationFlags]::ProcessSchemaLocation -bor
        [System.Xml.Schema.XmlSchemaValidationFlags]::ReportValidationWarnings
    }
    PROCESS {
        $xmlReader = $null
        try {
            Write-Verbose "Creating XML Reader..."
            $xmlReader = [System.Xml.XmlReader]::Create($Path, $settings)
            Write-Verbose "Validating..."
            Write-Debug "Path: $Path"
            Add-Type -AssemblyName System.Xml.Linq
            try {
                Write-Verbose "Loading XML file..."
                $null = [System.Xml.Linq.XDocument]::Load($xmlReader)
            }
            catch [System.Xml.XmlException], [System.Xml.Schema.XmlSchemaValidationException] {
                $validXmlFile = $false
                $error = $_.Exception.Message
            }
            finally {
                Write-Verbose "Validation done!"
            }
        }
        catch [System.ArgumentNullException] {
            Write-Error "$_.Exception.Message"
        }
        finally {
            if ($xmlReader) {
                $xmlReader.Close()
            }
        }
    
    }
    END {
        Write-Verbose "Setting results..."
        $xmlValidationObj | Add-Member -MemberType NoteProperty -Name $CONST_PATH -Value $Path -Force
        $xmlValidationObj | Add-Member -MemberType NoteProperty -Name $CONST_IS_VALID -Value $validXmlFile -Force
        $xmlValidationObj | Add-Member -MemberType NoteProperty -Name $CONST_ERROR -Value $error -Force
        return $xmlValidationObj
    }
}