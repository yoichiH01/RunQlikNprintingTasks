# MIT License
# 
# Copyright (c) 2019 Yoichi Hirotake
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE`
# SOFTWARE.
# RunNprintingTasks v1.0 

$NprintingFQDN = "QlikServer1.domain.local" #FQDN of Nprinting Server. Please change it based on your environment

$url = "https://$($NprintingFQDN):4993/api/v1/login/ntlm"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$s = Invoke-RestMethod -UseDefaultCredentials -Uri $url -Method Get -SessionVariable websession
$cookies = $websession.Cookies.GetCookies($url)
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.Cookies.Add($cookies);
$xsrf_token = $($cookies | Where-Object {$_.Name -eq "NPWEBCONSOLE_XSRF-TOKEN"}).Value

$hdrs = @{}
$hdrs.Add("X-XSRF-token",$xsrf_token)

$url = "https://$($NprintingFQDN):4993/api/v1/tasks"
$tasks = $(Invoke-RestMethod -WebSession $session -Uri $url -Method Get -Headers $hdrs).data.items
foreach ($task in $tasks) {
$taskid = $task.id
#$taskid
$url = "https://$($NprintingFQDN):4993/api/v1/tasks/$($taskid)/executions"
$invoke = Invoke-RestMethod -WebSession $session -Uri $url -Method Post -Headers $hdrs
}
