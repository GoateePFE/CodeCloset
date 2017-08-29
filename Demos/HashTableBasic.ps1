$User = @{
    Name   = 'Benny'
    Role   = 'Construction'
    ID     = 123
    Groups = 'Users','Admins','Network'
}

# Read 
$User
$user.Name
$user.Groups
$user.Groups[1]
$user.Groups += ('IT','Marketing')

# Add
$user.Shift = 'Day'
$user.add('Status','Fulltime')
$User

# Update
$user.shift = 'Evening'

# Remove
$user.remove('Shift')

$User

$User.Keys
$User.Values

