# Proposer (c) 2006 Mickael Faivre-Macon
# given a list of things someone own, and several other people list
# propose a next thing to the initial person in function of other pepole items
class Proposer

	attr_accessor :db # array of [user,item]
	attr_reader :users # resembling users [user,count]
	attr_reader :items # items in common [item, count]
	attr_reader :user_items # items for current user
	attr_reader :proposed_items # [item, weight]

	def initialize
		@db = [] 
		@user_item = []
		@users = []
		@items = []
		@proposed_items = Hash.new(0)
	end

	# fill @proposed_items, @users, @items
	# a ordonned list (by count) of proposed item [item,count]
	# a ordonned list (by count) of user [user,count]
	def propose(user)
		# for each user's items, get a pondered list of users who possess the most commun items,
		# and a list of most commun items from this list
		@user_items = get_items(user,[])
		users = Hash.new(0)
		items = Hash.new(0)
		@user_items.each { |item|
			fill_users_items(item,user,users,items)
			#puts "once item #{item} processed: users: #{users.to_a.join('.')}, items: #{items.to_a.join('.')}"
			}
		@items = items.sort{|x,y| x[1]<=>y[1]}.reverse	
		@users = users.sort{|x,y| x[1]<=>y[1]}.reverse
		@users.each { |u,c|		# get ordonned list (by count) of most common item not possessed by user		
			i = get_items(u,user_items)
			i.each { |it|
				@proposed_items[it] += users[u] # was 1 by default, but in fact better to add the number of items this user has in common
				}
			}
		@proposed_items = @proposed_items.sort{|x,y| - (x[1]<=>y[1])}
	end
	
	# return an array of all items for a user excluding ex_items
	def get_items(user,ex_items)
		rv = []
		db.each { |x,y|
			rv << y if(x==user)
			}
		rv - ex_items
	end
	
private
	
	# fill 2 hashes:
	# - u = hash of [user,count]
	# - i = ordonned list (by count) of [item, count]
	# params: item is the item to count, exuser is the user to exclude
	def fill_users_items(item,exuser,users,items)
		@db.each { |u,i|
			next if(u==exuser)
			if i == item
				users[u] += 1
				items[i] += 1
			end
			}
	end
	
end


#
# here is an exemple
#

if __FILE__ == $0
	#items_users = [[1,'A'],[1,'B'],[1,'C'],[2,'A'],[2,'B'],[2,'E'],[3,'A'],[3,'D'],[4,'C']] # shall deduce ['E','D'] for user 1
	
	items_users = []
	100.times { |i|
		a = [rand(10),(rand(26)+65).chr]
		if not items_users.include?(a)
			items_users << a 
			#puts "#{i}: user #{a[0]} has item #{a[1]}"
		end
		}
	
	p = Proposer.new
	p.db = items_users
	user = 0
	puts
	puts "proposing for user #{user}..."
	p.propose(user)
	
	puts "user #{user} items: #{p.user_items.join(',')}"
	p.items.each { |u,c|
		puts "item #{u} is owned by #{c} users other than user #{user}"
		}
	p.users.each { |u,c|
		puts "user #{u} has #{c} item in common, and has a weight of #{c}"
		puts "   user #{u} items: "+p.get_items(u,[]).join(',')
		}
	puts
	puts "Finally here is the list of proposed items for user #{user}"
	p.proposed_items.each { |item,count|
		puts "#{item} has a weight of #{count}"
		}
end
