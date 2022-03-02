configuration SSL
{
    Import-DscResource -ModuleName PsDesiredStateConfiguration
    Import-DscResource -ModuleName xWebAdministration
    Import-DscResource -Module xMakeCertificate

    node ("localhost")
    {
        xMakeCertificate CACert {
            Type                    = 'Root'
            Ensure                  = 'Present'
            CommonName              = 'CA'
            Store                   = 'Cert:\LocalMachine\CA'
            SubjectAlternativeNames = 'server.contoso.com'
            ExportPath              = 'C:\ca.pfx'
            PFXPassword             = 'Password'
        }
        
        xMakeCertificate SSLCert {
            Type                    = 'Web'
            Ensure                  = 'Present'
            CommonName              = 'Web'
            Store                   = 'Cert:\LocalMachine\My'
            SubjectAlternativeNames = 'server.contoso.com'
            SignerPath              = 'C:\ca.pfx'
            SignerPassword          = 'Passw0rd'
            DependsOn               = '[xMakeCertificate]CACert'
        }
        WindowsFeature WebServer {
            Ensure = "Present"
            Name   = "Web-Server"
        }

        File WebContent {
            Ensure          = 'Present'
            SourcePath      = 'c:\sources\mysite'
            DestinationPath = 'c:\intepub\mysite'
            Recurse         = $true
            Type            = 'Directory'
            DependsOn       = '[xMakeCertificate]SSLCert'
        }

        xWebSite MySite {
            Ensure       = 'Present'
            Name         = 'MySite'
            State        = 'Started'
            PhysicalPath = 'c:\intepub\mysite'
            BindingInfo  = @(
                MSFT_xWebBindingInformation {
                    Protocol             = 'HTTPS'
                    Port                 = 443
                    CertificateSubject   = 'CN=Web'
                    CertificateStoreName = 'MY'
                }
            )
            DependsOn    = @('[File]WebContent', '[WindowsFeature}WebServer', '[xMakeCertificate]SSLCert')
        }
    }
}