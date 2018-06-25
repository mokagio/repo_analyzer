require 'pathname'
require 'json'

puts "👓 Extracting data from Git..."

ignored_paths = [
  'Frameworks',
  'Carthage',
  'Static-Libraries',
  'Playgrounds'
]

selected_extensions = [
  '.swift'
]

git_churn_cmd = %{git log --all -M -C --name-only --format='format:' "$@" | sort | grep -v '^$' | uniq -c | sort -n | awk 'BEGIN {print "count\tfile"} {print $1 "\t" $2}'
}

churn_output = `#{git_churn_cmd}`.lines

churn_data = churn_output.map do |raw|
  components = raw.strip.split "\t"
  { file: components[1], churn: components[0].to_i }
end

churn_data = churn_data.reject do |d|
  ignored_paths.include?(Pathname(d[:file]).each_filename.first) || selected_extensions.include?(File.extname(d[:file])) == false
end

puts "👓 Extracting file length data..."

combined_data = []
churn_data.each do |data|
  next unless File.exist? data[:file]
  next if File.directory? data[:file]
  count = `wc -l "#{data[:file]}"`.strip.split(' ')[0].to_i
  combined_data.push({
    file: data[:file],
    churn: data[:churn],
    line_count: count
  })
end

puts "🧠 Crunching numbers..."

threshold = 15
# get the <threshold> longest files
longests = combined_data.sort_by { |d| d[:line_count] }
# get the <threshold> files with more churn
churnest = combined_data.sort_by { |d| d[:churn] }

puts JSON.pretty_generate (longests.reverse[0...threshold] + churnest.reverse[0...threshold]).uniq
