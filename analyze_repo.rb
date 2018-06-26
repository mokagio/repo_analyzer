require 'pathname'
require 'json'

puts "🔬 Extracting data from Git..."

ignored_paths = [
  'Frameworks',
  'Carthage',
  'Static-Libraries',
  'Playgrounds'
]

selected_extensions = [
  '.swift'
]

# https://github.com/garybernhardt/dotfiles/blob/master/bin/git-churn
git_churn_cmd = %{git log --all -M -C --name-only --format='format:' "$@" | sort | grep -v '^$' | uniq -c | sort -n | awk 'BEGIN {print "count\tfile"} {print $1 "\t" $2}'
}

churn_data = `#{git_churn_cmd}`
  .lines
  .map do |raw|
    components = raw.strip.split "\t"
    { file: components[1], churn: components[0].to_i }
  end
  .reject do |d|
    ignored_paths.include?(Pathname(d[:file]).each_filename.first) || selected_extensions.include?(File.extname(d[:file])) == false
  end

puts "🔬 Extracting file length data..."

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

longests = combined_data.sort_by { |d| d[:line_count] }
churnest = combined_data.sort_by { |d| d[:churn] }

threshold = 15
# get the <threshold> longest files and the <threshold> files with highest churn.
data = (longests.reverse[0...threshold] + churnest.reverse[0...threshold])
  .uniq
  .sort_by { |entry| entry[:churn] + entry[:line_count] }
  .reverse

def table_row(entry)
  """
<tr>
  <td>#{entry[:file]}</td>
  <td>#{entry[:churn]}</td>
  <td>#{entry[:line_count]}</td>
</tr>
  """
end

content = <<HTML
<!DOCTYPE html>
<html>
  <head>
    <!-- Original source http://bl.ocks.org/weiglemc/6185069 -->
    <!-- Example based on http://bl.ocks.org/mbostock/3887118 -->
    <!-- Tooltip example from http://www.d3noob.org/2013/01/adding-tooltips-to-d3js-graph.html -->
    <!-- Coding style based on http://gist.github.com/mbostock/5977197 -->
    <title>🔬 Repo analysis</title>

    <!-- Bootstrap CSS framework -->
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.0/css/bootstrap.min.css" integrity="sha384-9gVQ4dYFwwWSjIDZnLEWnxCjeSWFphJiwGPXr1jddIhOegiu1FwO5qRGvFXOdJZ4" crossorigin="anonymous" />

    <!-- D3.js powers the graphs rendering -->
    <script src="https://d3js.org/d3.v3.min.js"></script>

    <style>
body {
  margin-top: 2rem;
  margin-bottom: 2rem;
}

.axis path,
.axis line {
  fill: none;
  stroke: #000;
  shape-rendering: crispEdges;
}

.dot {
  stroke: #000;
}

.d3-tooltip {
  position: absolute;
  pointer-events: none;
  background-color: #333;
  color: white;
  padding: 8px;
  /* This is used to override Bootstrap's reboot */
  box-sizing: content-box;
}
    </style>
  </head>

  <body>

    <div class="container">
      <h1 style="display: inline-block">🔬 Repo analysis</h1>
      <p class="lead">
        The graph below shows a subset of the <code>.swift</code> files in your repository plotted against two metrics, Git churn and file length. Only the files with the highest churn and/or length are shown.
      </p>
      <p class="lead">
        Git churn is the number of commits on the file, how often it changes. File length is a rough but effective metric of the complexity of the code in the file (link needed).
      </p>
      <p class="lead">
        Complex files that change often are likely to be sources of bugs.
      </p>
      <p class="lead">
         <strong>The files in the top-right are great candidates to refactor</strong>. Working on them will provide a great return of time invested. This is why only the files with the highest churn and/or length are in the graph, the information shown is aimed to be actionable.
      </p>
      <p class="lead">
        Hover on a dot to see the file it represents. The full list of entries is in the table at the end of the page.
      </p>
      <div class="row mt-3">
        <div class="col-lg-12">
          <div id="graph"></div>
        </div>
      </div>
      <h3 class="mt-3">Where to go from here</h3>
      <p>
        Plotting Git churn against file length is only the tip of the iceberg in terms of information that can be mined out of a repository. Here are some ideas:
      </p>
      <ul>
        <li>Activity over time. A file might have high churn and complexity, but maybe it hasn't been touched in a long time and is part of a stable and well tested area of the codebase. There's not much to gain from refactoring it right now.</li>
        <li>Refine the definition of complexity. Customize it by combining metrics. E.g. file length, number of methods, cyclomatic complexity.</li>
        <li>Drill into the files. How's the complexity distributed across the different methods?</li>
        <li>Add a third dimension. E.g. test coverage or number of authors.</li>
      </ul>
      <p>If this sounds interesting to you please drop your email to learn about new developments.</p>

<!-- Begin MailChimp Signup Form -->
<div class="row mt-5 mb-5">
<div class="col-12">
<link href="//cdn-images.mailchimp.com/embedcode/slim-10_7.css" rel="stylesheet" type="text/css">
<div id="mc_embed_signup">
<form action="https://mokacoding.us10.list-manage.com/subscribe/post?u=45a265e2a9d2b9dbec5f98d51&amp;id=c47e871fc9" method="post" id="mc-embedded-subscribe-form" name="mc-embedded-subscribe-form" class="form-inline justify-content-center" target="_blank" novalidate>
    <div id="mc_embed_signup_scroll">
    <label class="sr-only">Email</label>
	<input type="email" value="" name="EMAIL" class="form-control" id="mce-EMAIL" placeholder="email address" required>
    <!-- real people should not fill this in and expect good things - do not remove this or risk form bot signups-->
    <div style="position: absolute; left: -5000px;" aria-hidden="true"><input type="text" name="b_45a265e2a9d2b9dbec5f98d51_c47e871fc9" tabindex="-1" value=""></div>
    <button type="submit" class="btn btn-primary">Subscribe</button>
    </div>
</form>
</div>
</div>
</div>
<!--End mc_embed_signup-->

      <p>You'll receive a welcome email with a link to a <a href="https://goo.gl/forms/6OIoidStIOuBO5Xu1">feedback form</a>. It would be super helpful if you could take the time to go through it. It won't take long.</p>

      <h3>Credits</h3>
      <p>
        I first came across the idea of plotting file churn against complexity in <a href="https://www.agileconnection.com/article/getting-empirical-about-refactoring">this article by Michael Feathers</a>.
      </p>
      <p>
        <a href="http://www.adamtornhill.com/">Adam Tornhill</a> took these ideas to the next level in his book <a href="https://pragprog.com/book/atcrime/your-code-as-a-crime-scene">Your Code as a Crime Scene</a>.
      </p>
      <p>
        Moreover, Tornhill has built <a href="https://codescene.io/">CodeScene</a>, a SaaS that provides this and the other analysis explored in the book, plus much more.
      </p>
      <p>
        Services like <a href="https://codeclimate.com/">Code Climate</a> offer a basic graph like the one above. <i>With more time put into the styling too.</i>
      <p>
      <p>
        The Git-foo used to extract the churn information has been shared by <a href="https://twitter.com/coreyhaines">Corey Haines</a> and <a href="https://twitter.com/garybernhardt">Gary Bernhardt</a>.
      </p>
      <h3 class="mt-5">All the files</h3>
      <div class="row">
        <div class="col-lg-12">
          <table class="table table-striped">
            <thead>
              <tr>
                <th scope="col">File</th>
                <th scope="col">Git Churn</th>
                <th scope="col">Length</th>
              </tr>
            </thead>
            <tbody>
HTML

data.each do |entry|
  content += table_row(entry)
end

content += <<HTML
            </tbody>
          </table>
        </div>
      </div>
      <div id="footer" class="row text-center mt-3">
        <div class="col-12">
          <p>Built with 💙 by <a href="https://twitter.com/mokagio">@mokagio</a>.</p>
          <p>Source available on <a href="">GitHub</a>.</p>
        </div>
      </div>
    </div>

    <script>
var margin = {top: 20, right: 20, bottom: 30, left: 40},
  width = 960 - margin.left - margin.right,
  height = 500 - margin.top - margin.bottom;

/*
 * value accessor - returns the value to encode for a given data object.
 * scale - maps value to a visual display encoding, such as a pixel position.
 * map function - maps from data value to display value
 * axis - sets up axis
 */

// setup x
var xValue = function(d) { return d.line_count;}, // data -> value
  xScale = d3.scale.linear().range([0, width]), // value -> display
  xMap = function(d) { return xScale(xValue(d));}, // data -> display
  xAxis = d3.svg.axis().scale(xScale).orient("bottom");

// setup y
var yValue = function(d) { return d.churn;}, // data -> value
  yScale = d3.scale.linear().range([height, 0]), // value -> display
  yMap = function(d) { return yScale(yValue(d));}, // data -> display
  yAxis = d3.svg.axis().scale(yScale).orient("left");

// setup fill color
var cValue = function(d) { return 10; /* TODO: change color depending on churn/lenght ratio */},
  color = d3.scale.category10();

// add the graph canvas to the body of the webpage
var svg = d3.select("#graph").append("svg")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)
  .append("g")
  .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

// add the tooltip area to the webpage
var tooltip = d3.select("body").append("div")
  .attr("class", "d3-tooltip")
  .style("opacity", 0);

var data = #{JSON.pretty_generate data}

// don't want dots overlapping axis, so add in buffer to data domain
xScale.domain([d3.min(data, xValue)-1, d3.max(data, xValue)+1]);
yScale.domain([d3.min(data, yValue)-1, d3.max(data, yValue)+1]);

// x-axis
svg.append("g")
  .attr("class", "x axis")
  .attr("transform", "translate(0," + height + ")")
  .call(xAxis)
  .append("text")
  .attr("class", "label")
  .attr("x", width)
  .attr("y", -6)
  .style("text-anchor", "end")
  .text("Length");

// y-axis
svg.append("g")
  .attr("class", "y axis")
  .call(yAxis)
  .append("text")
  .attr("class", "label")
  .attr("transform", "rotate(-90)")
  .attr("y", 6)
  .attr("dy", ".71em")
  .style("text-anchor", "end")
  .text("Git Churn");

// draw dots
svg.selectAll(".dot")
  .data(data)
  .enter().append("circle")
  .attr("class", "dot")
  .attr("r", 5)
  .attr("cx", xMap)
  .attr("cy", yMap)
  /*.style("fill", function(d) { return color(cValue(d));}) */
  .style("fill", "#007bff")
  .on("mouseover", function(d) {
    tooltip.transition()
      .duration(200)
      .style("opacity", .9);
    tooltip.html(d.file + "<br/> (Length: " + xValue(d) 
      + ", Git churn: " + yValue(d) + ")")
      .style("left", (d3.event.pageX + 5) + "px")
      .style("top", (d3.event.pageY - 28) + "px");
  })
  .on("mouseout", function(d) {
    tooltip.transition()
      .duration(500)
      .style("opacity", 0);
  });

/*
// draw legend
  var legend = svg.selectAll(".legend")
      .data(color.domain())
    .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });

// draw legend colored rectangles
  legend.append("rect")
      .attr("x", width - 18)
      .attr("width", 18)
      .attr("height", 18)
      .style("fill", color);

// draw legend text
  legend.append("text")
      .attr("x", width - 24)
      .attr("y", 9)
      .attr("dy", ".35em")
      .style("text-anchor", "end")
      .text(function(d) { return d;})
 */
    </script>
  </body>
</html>
HTML

path = './repo_analysis.html'

`rm #{path}` if File.exists? path

File.open(path, 'w') do |f|
  f << content
end

puts "✅ An HTML report has been generate in the current folder. Would you like to open it? Y/N [Y]"
should_open = STDIN.gets.chomp.downcase

`open #{path}` if should_open == 'y' || should_open == ''
