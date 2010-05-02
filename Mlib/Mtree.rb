class MTreeNode

	attr_reader :value, :children, :parent
	attr_writer :parent

	def initialize(value)
		@value = value
		@children = []
		@parent = nil
	end

end

class MTree

	def initialize
		@size = 0
		@roots = []
	end

	def size
		@size
	end

	def roots
		@roots
	end
	
	def addChild(value,parent=nil)
		n = MTreeNode.new(value)
		n.parent = parent;
		if(parent==nil)
			@roots << n
		else
			parent.children << n
		end
		@size += 1
		n
	end

  def getnextnode(from)
    return @roots[0] if from == nil
    return from.children[0] if from.children.size > 0
    return from.parent.children[from.parent.children.index(from)+1] if from.parent != nil and from.parent.children.index(from) < from.parent.children.size-1
    return nil
  end

end
