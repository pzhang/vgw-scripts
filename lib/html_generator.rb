require 'date'
require 'time'
require 'ftools'
class HTMLGenerator
  attr_accessor :search_dir
  def initialize(dir = nil)
    @search_dir = File.expand_path(dir) if dir
  end
  def make_all_pages(destination = ".", summary_data = {}, path_list = [], options = {})
    destination = File.expand_path(destination)
    File.makedirs(destination)
    Dir.chdir(destination)
    File.open(File.join(destination,
              DateTime.now.strftime("%m_%d_%Y")) + ".html", "w") do |f|
      doc = generate_page(path_list, :summary_data => summary_data,
                                     :date => DateTime.now.strftime("%m/%d/%Y"))
      f.write(doc)
    end
    dirlist = Dir.glob("*.html")
    dirlist << "index.html"
    dirlist.uniq!
    if options[:regenerate_index] != false
      File.open(File.join(destination, "index.html"), "w") do |f|
        doc = generate_index(dirlist.sort.reverse, summary_data, path_list)
        f.write(doc)
      end
    end

  end
  def  generate_page(list, options = {})
    doc = "<p><a href = \"index.html\"> Back to Index </a></p>"
    doc += "<p> Data for #{options[:date]}" if options[:date]
    doc ||= " "
    doc += generate_result_table(list, options[:summary_data])
    return page_gen(doc)
  end

  def generate_result_table(path_hash, summary_data = {})
    doc = ""
    lists = []
    lists << ['day' , path_hash['day'] || []] <<
             ['week', path_hash['week'] || []] << 
             ['month',path_hash['month'] || []]
    lists.compact!
    lists.each do |list|
      doc += "<p style = \"text-align:" + 
             "center\"><b> #{list[0].capitalize} Data </b></p>"
      matches = (list[1].first || "").match(/(\d+_\d+_\d+)_(\d+_\d+_\d+)/)
      if matches
        doc += "<p style = \"text-align:" +
               "center\"> #{matches[1].gsub("_","/")} - #{matches[2].gsub("_","/")}</p>"
      end
      doc += "<div style = \"text-align: center\"><table><tr>"
      c = 0
      sum_list = list[1].dup
      list[1].each do |l|
        doc += "<td><a href = \"#{l}\">" +
         "<img src = \"#{l}.small\" height = \"300\" width = \"300\"/></a></td>"
        if (c % 3 == 2)
          doc += "</tr><tr>" 
          3.times do |i|
            doc += "<td valign = \"top\">"
            doc += "<table><tr>"
            d = 0 
            summary_data[sum_list.shift].each_pair do |k, v|
              doc += "<td valign = \"top\"><p style = \"font-size: 75%\"><b>#{k} : </b></p>"
              v.each_pair do |k1, v1|
                doc += "<p style = \"font-size:75%\" >#{k1} : #{"%0.3f" % v1}</p>"
              end
              doc += "</td>"
              doc += "</tr><tr>" if (d % 3 == 2)
              d += 1
            end
            doc += "</table>"
            doc += "</td>"
          end
          doc += "</tr><tr>"
        end
        c += 1
      end
      doc += "</tr></table></div>"
    end
    return doc
  end

  def generate_index(list, summary_data = {}, img_list = [])
    doc = ""
    doc += "<FORM 
     METHOD=POST onChange= \"return dropdown(this.gourl)\">
    <SELECT NAME=\"gourl\">
    <OPTION VALUE=\"\">Choose another date..."
    list.each do |l|
      doc +=  "<OPTION VALUE=\"#{l}\">#{l.gsub("_","/").gsub(".html", "")}"
    end
    doc += "</SELECT></FORM>"
    doc += "<p> Data for #{DateTime.now.strftime("%m/%d/%Y")}</p>"
    doc += generate_result_table(img_list, summary_data)
    return page_gen(doc)
  end
  def page_gen(doc)
    a =  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
         \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
         <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
         <head>
          <meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />
          <style type=\"text/css\">
          table
          { 
            margin-left: auto;
            margin-right: auto;
            text-align: top;
          }

          </style>
         <SCRIPT TYPE=\"text/javascript\">
          <!--
       function dropdown(mySel)
       {
       var myWin, myVal;
       myVal = mySel.options[mySel.selectedIndex].value;
       if(myVal)
          {
          if(mySel.form.target)myWin = parent[mySel.form.target];
          else myWin = window;
          if (! myWin) return true;
          myWin.location = myVal;
          }
        return false;
        }
        //-->
        </SCRIPT>
         </head>
          <title> VGW Reporting Graphs </title>
          <body>"
    a+= doc
    a += "</body></html>"
    return a
  end
end
