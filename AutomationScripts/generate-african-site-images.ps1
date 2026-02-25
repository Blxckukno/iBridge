param(
    [switch]$UpdateReferences = $true
)

$ErrorActionPreference = "Stop"

if (-not $env:OPENAI_API_KEY) {
    Write-Error "OPENAI_API_KEY is not set. In PowerShell: `$env:OPENAI_API_KEY='your_key_here'"
}

$repoRoot = Resolve-Path "."
$generatedDir = Join-Path $repoRoot "Website/images/generated"
New-Item -ItemType Directory -Force -Path $generatedDir | Out-Null

$imageSpecs = @(
    @{
        Name = "contact-agent-african.png"
        Prompt = "Photorealistic image of a Black African female customer support agent wearing a headset, smiling while assisting a caller in a modern call center office, professional lighting, 16:9 composition, high detail, corporate style, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "it-support-african.png"
        Prompt = "Photorealistic image of a Black African male IT support specialist helping with a laptop at a desk, multiple monitors with dashboards, office environment, natural skin tones, high detail, professional corporate photography, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "ai-automation-african.png"
        Prompt = "Photorealistic image of two Black African professionals reviewing AI workflow charts on a large screen in a modern office, business attire, collaborative atmosphere, realistic, high detail, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "client-interaction-african.png"
        Prompt = "Photorealistic image of Black African business professionals in a client interaction meeting, one person presenting while others engage attentively, modern office conference room, professional look, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "about-team-african.png"
        Prompt = "Photorealistic image of a diverse Black African corporate team standing together in an office, confident and approachable expressions, smart business-casual clothing, bright natural lighting, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "bpo-operations-african.png"
        Prompt = "Photorealistic image of a Black African BPO operations floor with multiple agents at workstations, professional setup, realistic office environment, high detail, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "intranet-collab-african.png"
        Prompt = "Photorealistic image of Black African employees collaborating around a digital dashboard in an internal office workspace, teamwork focus, realistic, high detail, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "lms-learning-african.png"
        Prompt = "Photorealistic image of a Black African learner using an online training platform on a laptop in a bright office setting, focused expression, modern corporate education context, no text, no logos."
        Size = "1536x1024"
    },
    @{
        Name = "team-member-1-african.png"
        Prompt = "Professional headshot photo of a Black African woman in business attire, neutral studio background, realistic skin tones, high detail, corporate portrait, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "team-member-2-african.png"
        Prompt = "Professional headshot photo of a Black African man in business attire, neutral studio background, realistic skin tones, high detail, corporate portrait, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "team-member-3-african.png"
        Prompt = "Professional headshot photo of a Black African woman in smart casual office clothing, neutral studio background, realistic, high detail, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "team-member-4-african.png"
        Prompt = "Professional headshot photo of a Black African man in a blazer, neutral studio background, realistic, high detail, corporate portrait, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "team-member-5-african.png"
        Prompt = "Professional headshot photo of a Black African woman with confident expression, business attire, neutral studio background, realistic, high detail, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "team-member-6-african.png"
        Prompt = "Professional headshot photo of a Black African man with friendly expression, business attire, neutral studio background, realistic, high detail, no text, no logos."
        Size = "1024x1024"
    },
    @{
        Name = "og-african-customer-support.png"
        Prompt = "Photorealistic banner image for customer support website showing Black African professionals in a modern call center, warm and professional mood, clean composition, no text, no logos."
        Size = "1536x1024"
    }
)

function Invoke-OpenAIImageGeneration {
    param(
        [string]$Prompt,
        [string]$Size
    )

    $headers = @{
        "Authorization" = "Bearer $($env:OPENAI_API_KEY)"
        "Content-Type"  = "application/json"
    }

    $body = @{
        model  = "gpt-image-1"
        prompt = $Prompt
        size   = $Size
    } | ConvertTo-Json -Depth 5

    return Invoke-RestMethod -Method POST -Uri "https://api.openai.com/v1/images/generations" -Headers $headers -Body $body
}

foreach ($spec in $imageSpecs) {
    $outPath = Join-Path $generatedDir $spec.Name
    Write-Host "Generating $($spec.Name)..."
    $resp = Invoke-OpenAIImageGeneration -Prompt $spec.Prompt -Size $spec.Size
    $b64 = $resp.data[0].b64_json
    [IO.File]::WriteAllBytes($outPath, [Convert]::FromBase64String($b64))
}

if ($UpdateReferences) {
    $refMap = @{
        "images/scenes/contact-agent.svg"       = "images/generated/contact-agent-african.png"
        "images/scenes/it-support-desk.svg"     = "images/generated/it-support-african.png"
        "images/scenes/ai-automation.svg"       = "images/generated/ai-automation-african.png"
        "images/scenes/client-interaction.svg"  = "images/generated/client-interaction-african.png"
        "images/scenes/about-team.svg"          = "images/generated/about-team-african.png"
        "images/scenes/bpo-operations.svg"      = "images/generated/bpo-operations-african.png"
        "images/scenes/intranet-collab.svg"     = "images/generated/intranet-collab-african.png"
        "images/scenes/lms-learning.svg"        = "images/generated/lms-learning-african.png"
        "images/avatars/team-1.svg"             = "images/generated/team-member-1-african.png"
        "images/avatars/team-2.svg"             = "images/generated/team-member-2-african.png"
        "images/avatars/team-3.svg"             = "images/generated/team-member-3-african.png"
        "images/avatars/team-4.svg"             = "images/generated/team-member-4-african.png"
        "images/avatars/team-5.svg"             = "images/generated/team-member-5-african.png"
        "images/avatars/team-6.svg"             = "images/generated/team-member-6-african.png"
        "images/ibridge-og-image.jpg"           = "images/generated/og-african-customer-support.png"
    }

    $htmlFiles = Get-ChildItem "Website" -Recurse -File -Include *.html
    foreach ($f in $htmlFiles) {
        $content = Get-Content $f.FullName -Raw
        if ($null -eq $content) { continue }
        $newContent = $content
        foreach ($k in $refMap.Keys) {
            $newContent = $newContent.Replace($k, $refMap[$k])
        }
        if ($newContent -ne $content) {
            Set-Content $f.FullName $newContent -Encoding UTF8
        }
    }
}

Write-Host "Done. Generated images in Website/images/generated"
