# Guard-Xcoder

This guard uses the [Xcoder](https://github.com/rayh/xcoder) to provide monitoring of your Xcode projects for changes and launch clean, build, and package actions in response.

Guard-xcoder does not simply monitor all source files within a directory, it looks at the project file and finds the source files that are specifed in a target's source build files. It also currently will rebuild when the global PCH file has been changed as well.

## Install
  
Make sure you have [guard](http://github.com/guard/guard) installed.

Install the gem with:

    gem install guard-xcoder

Add it to your Gemfile:

    gem 'guard-xcoder'

And then add a basic setup to your Guardfile:

    guard init xcoder


## Usage

#### Cleaning, Building and Testing when anything changes for the project named 'TestProject'

```ruby
guard 'xcoder', :actions => [ :clean, :build, :test ] do
  watch('TestProject')
end
```

#### Building when anything changes for the target named 'Specs' in the 'TestProject'

```ruby
guard 'xcoder' :actions => [ :build ] do
  watch('TestProject//Specs')
end
```

#### Cleaning, Building, and Packaging when source files within 'AppStoreSubmission' change 

```ruby
guard 'xcoder' :actions => [ :clean, :build, :package ] do
  watch('TestProject//AppStoresubmission')
end
```

## Limitations

Currently `guard-xcoder` does not re-evaluate the file watchers when the project file changes.
This should hopefully be present in a future release.
