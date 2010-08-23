#encode:utf-8 
require "csv"
require "erb"
require "iconv"

$sortName=['p_all','p_lihe','p_wutang','p_baojian','p_yingyang']
$sortCH=['所有分类','高档礼盒','无糖食品','保健食品','营养食品']
$pageList=18

class Product
	
	def makepage(template,output=".")
		begin
			File.new("#{output}/#{con(@code)}/index.html", "w").puts ERB.new(template).result(binding)
		rescue
			puts "No this #{@code}"
		end
	end
	def initialize(row)
		@code = con(row[0])
		@name = con(row[1])
		@type = con(row[2])
		@size = con(row[3])
		@barcode = con(row[4])
		@text = con(row[5])
		@item = con(row[6])
		@eat = con(row[7])
		@save = con(row[8])
		@gb = con(row[9])
		@gmp = con(row[10])
		@giveup =con(row[11])
		@create = con(row[12])
		@taobao =con(row[13])
	end
	attr_reader :code,:name,:type,:size,:barcode,:text,:item,:eat,:save,:gb,:gmp,:giveup,:create

	def con(str)
		Iconv.conv('utf-8','gbk',str)
	end
end

class PageIndex
	def initialize(sort,list,pagenum,page,template)
		@list=list
		@sortname=$sortCH[sort]
		@sortdir=$sortName[sort]
		@pn=page
		@pages=1..pagenum
		@up= pn==1 ? 1: pn-1
		@down= pn==pagenum ? pn : pn+1
		@template=template
	end
	attr_reader :list,:sortname,:sortdir,:pn,:pages
	def makeindex
		File.new("#{@sortdir}#{@pn}.html", "w").puts ERB.new(@template).result(binding)
	end
end

class BuildPage
	def initialize(list_dir,sort_dir,c_erb,l_erb,output='.')
		#读取 内容模板
		@erb_content=File.read(c_erb)
		#读取 列表模板
		@erb_list=File.read(l_erb)
		#产品库 哈希 { 类别 => 产品[] }
		@products={'0'=>[],'1'=>[],'2'=>[],'3'=>[],'4'=>[]}
		#产品总数
		@pall =0
		
		load_csv(list_dir,sort_dir)
		
	end
	def content
		puts "build content. all:#{@pall}"
		@products['0'].each do |p|
			puts "write page #{p.code}/#{@pall}"
			p.makepage(@erb_content)
		end
	end
	
	def load_csv(list_dir,sort_dir)
		#读取产品资料 csv
		plist = CSV.read(list_dir)
		#读取产品类别 csv
		sort=CSV.read(sort_dir)
		
		#去除表头
		plist.shift
		sort.shift
		
		#产品类别与标号对应哈希表 {'编号','类别1,类别2'}
		slist=Hash.new
		#解析产品类别
		sort.each{|s|
			slist.store(s[0],s[1])
		}
		#填入产品数据到 slist
		plist.each{|data|
			#建立产品对象
			product = Product.new(data)
			#加入产品库
			@products['0'] << product
			slist[product.code].split(',').each{|kind|
				@products[kind] << product
			}
		}
		@pall = @products['0'].size
	end
	
	def list()
		#建立索引
		(0..4).each do |s|
			
			total = @products[s.to_s].size
			
			if total == $pageList then
				num=1
			else
				num=total / $pageList + 1
			end
			puts "start build sort [#{$sortName[s]}] pages:#{num} all:#{total}"
			
			(1..num).each do |page|
				at=page * $pageList
				
				head = at - $pageList
				
				if head < 0 then head =0 end
				
				foot = at - 1
				
				if at > total then foot = total - 1 end
				
				list=@products[s.to_s].values_at(head..foot)
				
				#建立列表页面 [sort , list , pagenum , page , template]
				pageindex=PageIndex.new(s,list,num,page,@erb_list)
				puts "building page '#{$sortName[s]}#{page}.html' ( #{head+1}-#{foot+1} ). -- at=#{at}"
				pageindex.makeindex
				
			end
			
			puts 
		end
	end
end

work = BuildPage.new('plist.csv','sort.csv','product-content.erb','product-list.erb')
work.content
work.list