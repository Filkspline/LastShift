class_name Variables
extends Node

# Contains all the variables and parses updates for them

var string_vars: Dictionary[String, String]
var int_vars: Dictionary[String, int]

func clear(): string_vars.clear(); int_vars.clear()


###########
# Parsers #
###########
# Flags:
# %name = read value from var 'name'
# { expr } = predicate (<, >, ==)
# functions: varname++(increment), varname=value

## Replace vars with words
func format_string(line: String)->String:
	var words = line.split(" ")
	var word
	for i in range(words.size()):
		word = words[i]
		if word.begins_with("%"): words[i] = read_var(word)
		
		# Remove expressions but still evaluate them
		if word.begins_with("{"): 
			read_var(word)
			words[i] = ""
	
	return " ".join(_strip(words))


## Parse a predicate string -> learn implicit type (NO NESTED EXPRESSIONS)
func _parse_expr(line: String) -> bool:
	var args: PackedStringArray = _strip(line.trim_prefix("{").trim_suffix("}").split(" "))
	
	# If a setter, just run that
	if args.size() == 1:
		read_var(args[0])
		return true
	
	# Switch statement for operations
	match args[1]:
		"==":
			return read_var(args[0]) == read_var(args[2])
		"<":
			return read_var(args[0]) < read_var(args[2])
		">":
			return read_var(args[0]) > read_var(args[2])
		"=":
			_set_var(args[0], args[2])
			return true
		_:
			assert(false, "unrecognised expression "+args[1])
	return false

## Parse a variable statement for the varible's value, or return predicate value or literal
func read_var(name: String)->String:
	if name.begins_with("{"): return str(_parse_expr(name))
	if !name.begins_with("%"): return name
	
	var n = name.trim_prefix("%")
	
	# Do operations on variable expression
	if name.ends_with("++"):
		n = n.trim_suffix("++")
		_increment(n.trim_suffix("++"))
	if name.contains("="):
		var n_split = n.split("=")
		assert(n_split.size() == 2, "Incomplete = expression at "+name)
		_set_var(n_split[0], n_split[1])
		return n_split[1]
	
	return _get_var(n)

## Remove empty whitespace elements from an input PackedStringArray
func _strip(lines: PackedStringArray)->PackedStringArray:
	var arr = Array(lines).filter(func(a: String)->bool: return a.length()>=1)
	#print(arr)
	return PackedStringArray(arr)


#####################
# Setters & Getters #
#####################

## Create or set variable under 'name' as int or string var depending on type of 'value'
func _set_var(n: String, value: String):
	var name = n.trim_prefix("%")
	assert (!name.contains(" ") && !name.contains("="), 
		"Illegal characters in variable name "+name)
	assert (!value.contains(" ") && !value.contains("="), 
		"Illegal characters in variable name "+value)
	
	if !string_vars.has(name) && value.is_valid_int():
		int_vars[name] = int(value)
	elif !int_vars.has(name):
		string_vars[name] = value
	else: assert(false, "Variable "+name+" does not exist of that type")


## Get a value
func _get_var(name: String)->String:
	if string_vars.has(name): 
		return string_vars[name]
	if int_vars.has(name): 
		return str(int_vars[name])
	
	assert(false, "Variable "+name+" does not exist")
	return ""

## Get var cast as int
func _get_int_var(name: String)->int:
	assert(int_vars.has(name), "Int variable "+name+" does not exist")
	return int(_get_var(name))

## Delete a var
func _delete(name: String):
	if string_vars.has(name): 
		string_vars.erase(name)
		return
	if int_vars.has(name): 
		int_vars.erase(name)
		return
	
	assert(false, "Variable "+name+" does not exist")


## Increment an int var
func _increment(name: String):
	assert(int_vars.has(name), "Int variable "+name+" does not exist")
	int_vars[name] = _get_int_var(name) + 1
