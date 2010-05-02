# traversal of graph for e.g., to find degree of separation of two people
# in social network or distance in hops of two network nodes.
#
# ported by steve ross (sxross at gmail dot com) from Python implementation
# http://www.python.org/doc/essays/graphs.html. Python licensed under
# PSF license.

#graph = {
#        'joe' => ['sam', 'bob'],        # joe has two friends, sam and bob
#        'sam' => ['bob', 'david'],      # sam has two friends, bob and david
#        'bob' => ['david'],             # bob only has one friend, david
#        'david' => ['bob'],             # and david has bob as a friend
#        'richard' => ['alex'],          # richard only has one friend, alex
#        'alex' => ['bob']               # alex has one friend, bob (who interestingly does not reciprocate)
#        }
        
def find_path(graph, start_point, end_point, path = [])
  path += [start_point]
  return path if start_point == end_point
  return nil if graph[start_point].nil?
  graph[start_point].each do |node|
    if !path.include? node
      new_path = find_path(graph, node, end_point, path)
      return new_path
    end
  end
end

def find_all_paths(graph, start_point, end_point, path = [])
  path += [start_point]
  return [path] if start_point == end_point
  return [] if graph[start_point].nil?
  paths = []
  graph[start_point].each do |node|
    if !path.include? node
      new_paths = find_all_paths(graph, node, end_point, path)
      new_paths.each{|new_path| paths << new_path}
    end
  end
  return paths
end

def find_shortest_path(graph, start_point, end_point, path = [])
  path += [start_point]
  return path if start_point == end_point
  return nil if graph[start_point].nil?
  shortest = nil
  graph[start_point].each do |node|
    if !path.include? node
      new_path = find_shortest_path(graph, node, end_point, path)
      if new_path
        shortest = new_path if !shortest || new_path.size < shortest.size
      end
    end
  end
  return shortest
end

#puts find_path(graph, 'joe', 'david').inspect
#puts '-' * 40
#puts find_all_paths(graph, 'joe', 'david').inspect
#puts '-' * 40
#puts find_shortest_path(graph, 'joe', 'david').inspect

