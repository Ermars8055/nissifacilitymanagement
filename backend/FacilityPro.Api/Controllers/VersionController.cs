using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace FacilityPro.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class VersionController : ControllerBase
{
    // Update these values each time you upload a new APK to the server
    private const string LatestVersion = "1.0.9";
    private const string ApkUrl = "https://management.ermarscastar.in/uploads/FacilityPro_1.0.9.apk";

    [AllowAnonymous]
    [HttpGet("latest")]
    public IActionResult GetLatest()
    {
        return Ok(new
        {
            version = LatestVersion,
            apkUrl = ApkUrl,
            releaseNotes = "Added Native 3D WebViewer for mobile! View all buildings and floors directly from the app."
        });
    }
}
