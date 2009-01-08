require 'date'
require 'time'
require 'ftools'
class HTMLGenerator
  attr_accessor :search_dir
  def initialize(dir)
    @search_dir = File.expand_path(dir)
  end
  def make_all_pages(destination = ".")
    destination = File.expand_path(destination)
    File.makedirs(destination)
    Dir.chdir(search_dir)
    dirlist = Dir.glob("*")
    File.open(File.join(destination, "index.html"), "w") do |f|
      doc = generate_index(dirlist)
      f.write(doc)
    end
    dirlist.each do |d|
      Dir.chdir(File.join(search_dir, d))
      pics = Dir.glob("**/*.png")
      pics.map! {|p| File.join(Dir.pwd, p)}
      File.open(File.join(destination, "#{d}.html"), "w") do |f|
        doc = generate_page(pics)
        f.write(doc)
      end
    end
  end
  def  generate_page(list)
    doc = ""
    doc += "<ul>"
    list.each do |l|
      doc += "<l><img src = \"#{l}\" />"
    end
    doc += "</ul>"
    return page_gen(doc)
  end

  def generate_index(list)
    doc = ""

    Dir.chdir(File.join(search_dir, DateTime.now.strftime("%m_%d_%Y")))
    img_list = Dir.glob("**/*.png")   
    doc += "<ul>"
    img_list.each do |l|
      doc += "<l><img src = \"#{File.join(Dir.pwd, l)}\" />"
    end
    doc += "</ul>"

    doc += "<ul>"
    list.each do |l|
      doc += "<l><a href = \"#{l}.html\">#{l}</a>"
    end
    doc += "</ul>"
    return page_gen(doc)
  end
  def page_gen(doc)
    a =  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"
         \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">
         <html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">
         <head>
          <meta http-equiv=\"content-type\" content=\"text/html;charset=UTF-8\" />
         </head>
          <body>"
    a+= doc
    a += "</body></html>"
    return a
  end
end
