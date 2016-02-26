(function(){
	function iter$(a){ return a ? (a.toArray ? a.toArray() : a) : []; };
	var prefixes, rewrites, normalizeKey, Builder;
	// Vendor-prefix normalizing
	
	function contentify(value){
		var keyword = /^none|normal|open-quote|close-quote|no-open-quote|no-close-quote|(url|attr)\(.+|['"].+$/;
		
		if (keyword.test(value)) {
			return value;
		} else {
			value = value.replace(/["\\\n]/g,function(m) { return "\\" + m; });
			return '"' + value + '"';
		};
	};
	
	var compileCSS = 
		typeof window == "object" ? (
			// Browser version
			
			prefixes = ["Moz","O","ms","Webkit"],
			rewrites = {},
			
			normalizeKey = function(key,style) {
				if (key in style) {
					return key;
				};
				
				var capitalKey = key.charAt(0).toUpperCase() + key.substring(1);
				
				for (var i = 0, len = prefixes.length; i < len; i++) {
					var fullKey = prefixes[i] + capitalKey;
					if (fullKey in style) {
						return fullKey;
					};
				};
				
				return key;
			},
			
			function(props) {
				var doc = document.createElement("div");
				var style = doc.style;
				
				var $1;
				for (var key in props){
					var normKey = (rewrites[($1 = key)] || (rewrites[$1] = normalizeKey(key,style)));
					style[normKey] = props[key];
				};
				
				var text = style.cssText;
				if (props.content) {
					text += ("content: " + contentify(props.content) + ";");
				};
				return text;
			}
		) : (
			// Basic server-side version
			function(props) {
				var code = "";
				var val;
				for (var key in props){
					val = props[key];var cssKey = key.replace(/([A-Z]+)/g,function(match) {
						return ("-" + (match.toLowerCase()));
					});
					if (key == "content") { val = contentify(val) };
					code += ("" + cssKey + ": " + val + ";");
				};
				return code;
			}
		)
	;
	
	function Builder(){
		this._groups = [];
		this._blockPatchers = {};
		this._isFrozen = false;
		
		this.defineBlock("main",function(code) {
			return code;
		});
	};
	
	var UNIQ = 0;
	
	Builder.prototype.defineBlock = function (name,code){
		return this._blockPatchers[name] = code;
	};
	
	Builder.prototype.defineBlockAlias = function (from,to){
		return this.defineBlock(from,function(code) {
			return ("" + to + " \{ " + code + " \}");
		});
	};
	
	Builder.prototype.freeze = function (code){
		this._isFrozen = true;
		if (code) {
			code();
			this._isFrozen = false;
		};
		return this;
	};
	
	Builder.prototype.create = function (props,className){
		if (this._isFrozen) {
			throw new Error("Styles have been frozen");
		};
		
		className || (className = ("imba-st-" + (UNIQ++)));
		var sg = new StyleGroup(className);
		sg.parse(props,"&","main");
		this._groups.push(sg);
		this._result = null;
		return sg;
	};
	
	Builder.prototype.insert = function (t,styles){
		var proto = t.prototype;
		;
		for (var key in styles){
			var ivar = ("_" + key);
			var group = this.create(styles[key]);
			group.setParent(proto[ivar]);
			proto[ivar] = group;
		};
		return this;
	};
	
	Builder.prototype.toString = function (){
		return this._result || (this._result = this.build());
	};
	
	Builder.prototype.build = function (){
		var allRuleSets = [];
		var matchingSelectors = [];
		
		for (var i = 0, ary = iter$(this._groups), len = ary.length, group; i < len; i++) {
			// Follow the parent-chain
			group = ary[i];
			var curr = group;
			while (curr){
				for (var j = 0, items = iter$(curr.ruleSets()), len_ = items.length, rs; j < len_; j++) {
					rs = items[j];
					var idx = allRuleSets.indexOf(rs);
					if (idx == -1) {
						idx = allRuleSets.length;
						allRuleSets[idx] = rs;
						matchingSelectors[idx] = [];
					};
					matchingSelectors[idx].push(("." + (group.className())));
				};
				curr = curr.parent();
			};
		};
		
		var blocks = {};
		
		for (var idx1 = 0, len = allRuleSets.length, rs1; idx1 < len; idx1++) {
			rs1 = allRuleSets[idx1];
			var selectors = matchingSelectors[idx1];
			blocks[($1 = rs1.block())] || (blocks[$1] = "");
			blocks[rs1.block()] += rs1.toCSS(selectors);
		};
		
		var result = "";
		
		var value;
		for (var key in blocks){
			value = blocks[key];var patcher = this._blockPatchers[key];
			
			var code = patcher ? (
				patcher(value,key)
			) : (
				("" + key + " \{ " + value + " \}")
			);
			
			result += code;
		};
		
		return result;
	};
	
	function StyleGroup(className){
		this._className = className;
		this._ruleSets = [];
	};
	
	StyleGroup.prototype.className = function(v){ return this._className; }
	StyleGroup.prototype.setClassName = function(v){ this._className = v; return this; };
	StyleGroup.prototype.parent = function(v){ return this._parent; }
	StyleGroup.prototype.setParent = function(v){ this._parent = v; return this; };
	StyleGroup.prototype.ruleSets = function(v){ return this._ruleSets; }
	StyleGroup.prototype.setRuleSets = function(v){ this._ruleSets = v; return this; };
	
	StyleGroup.prototype.addRuleSet = function (rs){
		this._ruleSets.push(rs);
		return this;
	};
	
	StyleGroup.prototype.parse = function (props,scope,block){
		var ruleProps = {};
		var isEmpty = true;
		
		var val;
		for (var keyString in props){
			val = props[keyString];var keys = keyString.split(/\s*,\s*/);
			for (var i = 0, ary = iter$(keys), len = ary.length, key; i < len; i++) {
				key = ary[i];
				if (key[0] == "@") {
					this.parse(val,scope,key);
				} else if (key[0] == ":") {
					this.parse(val,scope + key,block);
				} else if (/&/.test(key)) {
					scope = key.replace(/&/,scope);
					this.parse(val,scope,block);
				} else {
					ruleProps[key] = val;
					isEmpty = false;
				};
			};
		};
		
		if (!isEmpty) {
			var rs = new RuleSet(ruleProps,{scope: scope,block: block});
			return this.addRuleSet(rs);
		};
	};
	
	function RuleSet(props,options){
		this._props = props;
		this._scope = options.scope;
		this._block = options.block;
		this._code = compileCSS(props);
	};
	
	RuleSet.prototype.block = function(v){ return this._block; }
	RuleSet.prototype.setBlock = function(v){ this._block = v; return this; };
	RuleSet.prototype.scope = function(v){ return this._scope; }
	RuleSet.prototype.setScope = function(v){ this._scope = v; return this; };
	RuleSet.prototype.code = function(v){ return this._code; }
	RuleSet.prototype.setCode = function(v){ this._code = v; return this; };
	
	RuleSet.prototype.toCSS = function (selectors){
		var scope = this._scope;
		var fullSelector = ((function() {
			for (var i = 0, ary = iter$(selectors), len = ary.length, res = []; i < len; i++) {
				res.push(scope.replace("&",ary[i]));
			};
			return res;
		})()).join(", ");
		return ("" + fullSelector + " \{ " + (this._code) + " \}");
	};
	
	// Default buider
	module.exports = new Builder();
	return module.exports.Builder = Builder = Builder;
	

})();