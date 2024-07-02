# Organize the input parameters.
param (
	[Alias('h')]
	[Switch]$hard,

	[Alias('s')]
	[Switch]$soft,

	[Alias('r')]
	[Switch]$remote,

	[Alias('n')]
	[int]$number
)

# Validate the input arguments.
if ($hard -and $soft) {
	Write-Host "Error! Cannot perform a hard and soft reset simultaneously!" -ForegroundColor DarkRed
	exit 1
}

# Ensure number is at least 1.
if (-not $number -or $number -lt 1) {
	$number = 1
}

# Get list of commits.
$logs = git log --pretty=oneline

# Ensure number is within range.
$number = [Math]::Min($number, $logs.Length-1)

# Extract previous hash and message.
$hash = $logs[$number].split()[0]
$message = "$($logs[$number])".Substring(41)

# Format the local commit text to display below.
$localText = &{if ($hard) {"hard-"} elseif ($soft) {"soft-"} else {""}}

# Format the remote commit text to display below.
$remoteText = &{if ($remote) {"REMOTE reset and a "} else {""}}

# Format the message for previous commit.
$previous = &{if ($number -eq 1) {"to the previous commit"} else {"$number commits back"}}

# Display details of previous commit.
Write-Host "Performing a $($remoteText)LOCAL $($localText)reset $previous..." -ForegroundColor Green
Write-Host "message:  $message"
Write-Host "hash:     $hash"
Write-Host "════════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# Reset local branch to previous commit.
if ($hard) {
	git reset --hard $hash
} elseif ($soft) {
	git reset --soft $hash
} else {
	git reset $hash
}

# If desired, reset remote branch to previous commit.
if ($remote) {
	git push -f
}