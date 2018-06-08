# User.create(email: "admin@admin.com", password: "testing", admin: true)
# User.create(email: "user@user.com", password: "testing")
Activity.destroy_all
User.destroy_all
UserEvent.destroy_all


User.create!(
  email: "test1@test.com",
  password: "testing",
  first_name: "bob",
  last_name: "bobson",
  address: " 5333 Avenue Casgrain #102, Montréal, QC H2T 1X6" #.strip.gsub(/\s+/, " ").gsub(/(\(|\)|\#)/, "").unicode_normalize(:nfkd).encode('ASCII', replace: '')
  )

  User.create!(
  email: "test2@test.com",
  password: "testing",
  first_name: "john",
  last_name: "johnson",
  address: "6586 av de chateaubriand" #.strip.gsub(/\s+/, " ").gsub(/(\(|\)|\#)/, "").unicode_normalize(:nfkd).encode('ASCII', replace: '')
  )

{
  "run" => {
    name: "run",
    description: "Go for a Run",
    sunny_required: false,
    warm_required: false,
    dry_required: true,
    calm_required: true
  },
  "park" => {
    name: "park",
    description: "Spend Time in the Park",
    sunny_required: true,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "museum" => {
    name: "museum",
    description: "Go to a Museum",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false,
  },
  "bbq" => {
    name: "bbq",
    description: "Have a Barbeque",
    sunny_required: false,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "yoga" => {
    name: "yoga",
    description: "Do a Yoga Video",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "cinema" => {
    name: "cinema",
    description: "Go to the Cinema",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "drinks" => {
    name: "drinks",
    description: "Drinks on a Terrace",
    sunny_required: true,
    warm_required: true,
    dry_required: true,
    calm_required: true
  },
  "read" => {
    name: "read",
    description: "Read a Book",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  },
  "gallery" => {
    name: "gallery",
    description: "Check out an Art Gallery",
    sunny_required: false,
    warm_required: false,
    dry_required: false,
    calm_required: false
  }
}.values.each do |e|
 Activity.create(e)
end
