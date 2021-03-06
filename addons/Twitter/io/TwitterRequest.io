URL

Sequence asCamelized := method(
	split("_") map(i, v, if(i > 0, v asCapitalized, v)) join
)

TwitterRequest := Object clone do(
	host ::= "twitter.com"
	username ::= nil
	password ::= nil
	
	httpMethod ::= "get"
	path ::= nil
	
	queryParamNames ::= nil
	postParamNames ::= nil
	pathParamNames ::= nil
	fileParamName ::= nil
	
	init := method(
		setQueryParamNames(List clone)
		setPostParamNames(List clone)
		setPathParamNames(List clone)
	)
	
	response ::= nil
	
	//public
	
	execute := method(
		queryParams := Map clone
		queryParamNames foreach(name,
			if(v := self perform(name asCamelized asSymbol),
				queryParams atPut(name, v asString)
			)
		)
		queryString := if(queryParams size > 0, "?" .. queryParams asQueryString, "")
		
		postParams := Map clone
		postParamNames foreach(name,
			if(v := self perform(name asCamelized asSymbol),
				postParams atPut(name, v asString)
			)
		)
		
		pathParamNames foreach(name,
			if(v := self perform(name asCamelized asSymbol),
				path = path appendPathSeq(v asString)
			)
		)
		
		url := URL with("http://" .. host .. path .. ".json" .. queryString) setFollowRedirects(false)
		
		//writeln(url asString)
		
		if(username and password,
			url setUsesBasicAuthentication(true)
			url setUsername(username)
			url setPassword(password)
		)
		
		headers := Map clone
		
		if(fileParamName and file := self perform(fileParamName),
			ext := file path pathExtension
			if(ext == "jpg") then(
				type := "image/jpg"
			) elseif(ext == "gif") then(
				type := "image/gif"
			) elseif(ext == "png") then(
				type := "image/png"
			) else(
				type := "application/octet-stream"
			)
			
			boundary := Date clone now asNumber round asHex
			headers atPut("Content-Type", "multipart/form-data; boundary=" .. boundary)
			postParams = ("--" .. boundary .. "\r\n") asMutable
			postParams appendSeq(
				"Content-Disposition: form-data; name=\"#{URL escapeString(fileParamName)}\"; filename=\"#{file name}\"\r\n" interpolate
			)
			postParams appendSeq("Content-Type: " .. type .. "\r\n\r\n")
			postParams appendSeq(file contents)
			postParams appendSeq("\r\n")
			postParams appendSeq("--" .. boundary .. "--\r\n")
		)
		
		setResponse(TwitterResponse clone\
			setBody(if(httpMethod asLowercase == "get", url fetch, url post(postParams, headers)))\
			setStatusCode(url statusCode)\
			setRateLimitRemaining(url ?responseHeaders at("X-RateLimit-Remaining"))\
			setRateLimitExpiration(url ?responseHeaders at("X-RateLimit-Reset")))
		
		debugWriteln("TwitterResponse body[", response body, "]")
		debugWriteln("TwitterResponse statusCode[", response statusCode, "]")
		response
	)
	
	addQuerySlots := method(querySlotNames,
		querySlotNames split foreach(name,
			self newSlot(name asCamelized)
			queryParamNames appendIfAbsent(name)
		)
		self
	)
	
	addPostSlots := method(postSlotNames,
		postSlotNames split foreach(name,
			self newSlot(name asCamelized)
			postParamNames appendIfAbsent(name)
		)
		self
	)
	
	addPathSlots := method(slotNames,
		slotNames split foreach(name,
			self newSlot(name asCamelized)
			pathParamNames appendIfAbsent(name)
		)
		self
	)
	
	addFileSlot := method(slotName,
		self newSlot(slotName asCamelized)
		setFileParamName(slotName)
		self
	)
	
	asShowFriendship := method(
		setPath("/friendships/show")
		addQuerySlots("source_id source_screen_name target_id target_screen_name")
	)
	
	asFriendshipExists := method(
		setPath("/friendships/exists")
		addQuerySlots("user_a user_b")
	)
	
	asShow := method(
		setPath("/users/show")
		addQuerySlots("id user_id screen_name")
	)
	
	asCreateFriendship := method(
		setHttpMethod("post")
		setPath("/friendships/create")
		addQuerySlots("user_id screen_name follow")
	)
	
	asDestroyFriendship := method(
		self\
		setHttpMethod("post")\
		setPath("/friendships/destroy")\
		addQuerySlots("user_id screen_name")
	)
	
	asFriendIds := method(
		setPath("/friends/ids")
		addQuerySlots("user_id screen_name")
	)
	
	asFollowerIds := method(
		setPath("/followers/ids")
		addQuerySlots("user_id screen_name")
	)
	
	asUpdateAccountProfile := method(
		setHttpMethod("post")
		setPath("/account/update_profile")
		addPostSlots("name url location description")
	)
	
	asUpdateAccountProfileColors := method(
		setHttpMethod("post")
		setPath("/account/update_profile_colors")
		addPostSlots("profile_background_color profile_text_color profile_link_color profile_sidebar_fill_color profile_sidebar_border_color")
	)
	
	asUpdateAccountProfileImage := method(
		setHttpMethod("post")
		setPath("/account/update_profile_image")
		addFileSlot("image")
	)
	
	asUpdateAccountProfileBackgroundImage := method(
		setHttpMethod("post")
		setPath("/account/update_profile_background_image")
		addFileSlot("image")
		addQuerySlots("tile")
	)
	
	asUpdateStatus := method(
		setHttpMethod("post")
		setPath("/statuses/update")
		addQuerySlots("source")
		addPostSlots("status")
	)
	
	asSearch := method(
		setHost("search.twitter.com")
		setPath("/search")
		addQuerySlots("rpp page since_id q")
	)
	
	asRateLimitStatus := method(
		setPath("/account/rate_limit_status")
	)
)