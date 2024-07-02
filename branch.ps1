# Organize the input parameters.
param (
	[Alias('h')]
	[Switch]$help,

	[Alias('l')]
	[Switch]$link,

	[Alias('p')]
	[Switch]$prune,

	[Alias('s')]
	[Switch]$select,

	[Alias('d')]
	[Switch]$delete,

	[Alias('n')]
	[String]$new
)



# Show the help dialogue.
function Help {
	Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗"
	Write-Host "║ Usage: branch.ps1 [option] [value]                                             ║"
	Write-Host "║ arguments:                                                                     ║"
	Write-Host "║    -h, -help:     Shows the help dialogue                                      ║"
	Write-Host "║    -l, -link:     Links all remote branches with local branches                ║"
	Write-Host "║    -p, -prune:    Prunes all branches no longer in remote                      ║"
	Write-Host "║    -s, -select:   Selects an available branch to switch to                     ║"
	Write-Host "║    -d, -delete:   Deletes the specified branch, locally and remotely           ║"
	Write-Host "║    -n, -new:      Creates and links a new branch, locally and remotely         ║"
	Write-Host "║                                                                                ║"
	Write-Host "║ Opens this help dialogue if no arguments are provided.                         ║"
	Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝"
	exit 1
}



# Get list of all local and remote branches.
function ScanBranches {
	$branches = git branch -a
	$index = $branches.IndexOf($branches -like "*HEAD*")

	# Get all local branches.
	$local = New-Object 'String[]' ($index)
	for ($i = 0; $i -lt $local.Length; $i++) {
		$local[$i] = ($branches[$i] -split " ")[-1]
	}

	# Get all remote branches.
	$j = $index + 1
	$remote = New-Object 'String[]' ($branches.Length - $j)
	for ($i = 0; $i -lt $remote.Length; $i++) {
		$remote[$i] = ($branches[$j] -split "remotes/origin/")[-1]
		$j++
	}

	return $local, $remote
}



# Link all local and remote branches.
function LinkBranches($local, $remote) {

	# If branches don't exist locally, create them.
	foreach ($branch in $remote) {
		if (-not $local.Contains($branch)) {
			git branch $branch
			git branch --set-upstream-to=origin/$branch $branch
		}
	}

	# If branches don't exist remotely, create them.
	foreach ($branch in $local) {
		if (-not $remote.Contains($branch)) {
			git push origin $branch
			git branch --set-upstream-to=origin/$branch $branch
		}
	}
}



# Creates a new branch both locally and remotely.
function CreateNewBranch($branch) {
	$branch = $branch.ToLower().Replace(" ", "_")
	$local, $remote = ScanBranches
	$exists = $true

	# If local branch does not exist, create it.
	if (-not ($local.Contains($branch))) {
		git branch $branch
		$exists = $false
	}

	# If remote branch does not exist, create it.
	if (-not ($remote.Contains($branch))) {
		git push origin $branch
		$exists = $false
	}

	# Show error if branch already exists. Otherwise, link remote and local branch.
	if ($exists) {
		Write-Host "Error! Branch '$($branch)' already exists." -ForegroundColor DarkRed
	} else {
		git branch --set-upstream-to=origin/$branch $branch
	}
}



# Get a list of all local and remote branches.
function GetAllBranches() {

	# Get list of local branches.
	$localBranches = @(git branch | ForEach-Object {
		([string]$_)[2..$_.Length] -join ''  
	})

	# Get list of remote branches (excluding HEAD -> origin).
	$remoteBranches = @(git branch -r | ForEach-Object {
		([string]$_).Split("/")[1]
	})
	$remoteBranches = @($remoteBranches[1..$remoteBranches.Length])

	# Merge into a single list.
	$allBranches = @($localBranches + $remoteBranches | Select-Object -Unique | sort)
	return $allBranches
}


# Returns a new list of branches without the master branch.
function RemoveMasterFromList($allBranches) {
	$allBranches = @($allBranches)
	$numBranches = $allBranches.Length

	# Return null if only master branch.
	if ($numBranches -eq 1) {
		return @()
	}

	# Create empty array with one fewer branches.
	$mostBranches = @(foreach ($item in 2..$numBranches) { "" })

	# Copy all branches except master to the most branches array.
	$newIndex = 0
	for ($oldIndex = 0; $oldIndex -lt $numBranches; $oldIndex++) {
		if ($allBranches[$oldIndex] -ne "master") {
			$mostBranches[$newIndex] = $allBranches[$oldIndex]
			$newIndex++
		}
	}

	# Return all except master.
	return $mostBranches
}


# Select the branch to either switch to or to delete.
function SelectBranch($allBranches, $isSelecting) {

	# Display the respective instructions.
	if ($isSelecting) {
		Write-Host "`nSelect the branch to switch to by number:" -ForegroundColor Blue
	} else {
		Write-Host "`nSelect the branch to delete by number:" -ForegroundColor DarkRed
	}

	# List all branches.
	Write-Host ("═"*60)
	for ($i = 0; $i -lt $allBranches.Count; $i++) {
		$index = "$($i+1))".PadRight(5, " ")
		Write-Host "$($index)$($allBranches[$i])"
	}
	Write-Host ("═"*60)

	# Get user input.
	$index = -1
	while (-not ($index -in 1..$allBranches.Count)) {
		Write-Host "> " -NoNewline
		$index = $Host.UI.ReadLine().Trim()
	}

	# Return selected branch.
	return $allBranches[$index-1]
}


# Deletes a branch both locally and remotely.
function DeleteBranch($branch) {
	$branch = $branch.ToLower().Replace(" ", "_")
	$local, $remote = ScanBranches
	$missing = $true
	echo ""

	# If local branch exists, delete it.
	if ($local.Contains($branch)) {
		git branch -D $branch
		$missing = $false
	}

	# If remote branch exists, delete it.
	if ($remote.Contains($branch)) {
		git push origin --delete $branch
		rm .git/refs/remotes/origin/$branch -ErrorAction Ignore
		$missing = $false
	}

	# If neither exists, show error message.
	if ($missing) {
		Write-Host "Error! Branch '$($branch)' does not exist." -ForegroundColor DarkRed
	}
}



# The main operations of the script starts here.
################################################################################

# If an argument has not been provided, show the help dialogue.
if (-not ($link -or $prune -or $select -or $delete -or $new)) {
	$help = $true
}

# If help is requested, show the help menu and exit.
if ($help) {
	Help
}

# Link branches
if ($link) {
	$local, $remote = ScanBranches
	LinkBranches $local $remote
}

# Prune all branches not in remote.
if ($prune) {
	git remote prune origin
}

# Switch to the selected branched.
if ($select) {
	$allBranches = GetAllBranches
	$branch = SelectBranch @($allBranches) $true
	Write-Host "Switching to branch '$branch'`n"
	git checkout $branch
}

# Delete the specified branch.
if ($delete) {
	$allBranches = GetAllBranches
	$mostBranches = @(RemoveMasterFromList($allBranches))
	if ($mostBranches.Length -eq 0) {
		Write-Host "Only master branch remaining." -ForegroundColor DarkRed
	} else {
		$branch = SelectBranch($mostBranches)
		DeleteBranch($branch)
	}
}

# Create a new branch.
if ($new) {
	CreateNewBranch($new)
}
