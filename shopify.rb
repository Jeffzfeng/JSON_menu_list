require 'net/http'
require 'json'

# function to get pages to iterate through
def get_total_pages(pagination)
    total_menus = pagination["total"]
    per_page = pagination["per_page"]
    if total_menus%per_page == 0 
        total_pages = total_menus/per_page
    else
        total_pages = (total_menus/per_page) + 1
    end
    return total_pages
end

# parse json response into ruby object
def parse_json(url)
    uri = URI(url)
    response = Net::HTTP.get(uri)
    parsed_json = JSON.parse(response)
    return parsed_json
end 

# function to build initial menu_list
def build_menus_list(menus_list, curr_menu)
    # if parent_id == nil, set as root node
    if curr_menu["parent_id"] == nil
        new_menu_list_root = {"root_id" => curr_menu["id"], "children" => curr_menu["child_ids"]}
        menus_list.push(new_menu_list_root)
    # otherwise, check for parent and append to child_id list
    else
        menus_list.each do |roots|
            roots["children"].each do |child_nodes|
                if child_nodes == curr_menu["id"]
                    # append the two arrays and put into original list
                    roots["children"] = curr_menu["child_ids"] + roots["children"]
                    break
                end
            end
        end
    end
end

# function that checks for validity of original list
def validate_menus(menus_list)
    # create new hash that has two different list (for valid/invalid)
    final_menus_list = Hash.new
    final_menus_list["valid_menus"] = []
    final_menus_list["invalid_menus"] = []
    menus_list.each do |list|
        # sort inplace to save mem
        list["children"].sort!
        # check two conds: root not in child list and no dups in child list
        if(list["children"].include? list["root_id"] || (list["children"].uniq != list["children"]))
            final_menus_list["invalid_menus"].push(list)
        else
            final_menus_list["valid_menus"].push(list)
        end
    end
    return final_menus_list
end 

def parse_json_menus (url)
    # start at page 1
    page_num = 1
    # use url from first challenge
    first_page_url = url + '&page=%d' % [page_num]
    parsed_json = parse_json(first_page_url)
    menus_list = []
    
    #get menu from first page start building list of menus with roots and children
    first_page_menus = parsed_json["menus"]
    first_page_menus.each do |menu|
    build_menus_list(menus_list, menu)
    end
    
    #get total pages to iterate to find all menus
    first_page_info = parsed_json["pagination"]
    total_pages = get_total_pages(first_page_info)
    
    #increment page 
    page_num += 1
    
    while page_num<=total_pages
        # replace end of url with page_num as pages are iterated
        next_url =  url + '&page=%d' % [page_num]
        parsed_json = parse_json(next_url)
        next_page_menus = parsed_json["menus"]
        # attempt to add menu to existing menu list for each menu
        next_page_menus.each do |menu|
            build_menus_list(menus_list, menu)
        end
        page_num += 1
    end

    # filter for invalide menus
    final_menus_list = validate_menus(menus_list)
    return final_menus_list.to_json
end

# url for first challenge
url = 'https://backend-challenge-summer-2018.herokuapp.com/challenges.json?id=1'
puts parse_json_menus(url)

