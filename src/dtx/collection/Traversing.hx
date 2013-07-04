/****
* Copyright (c) 2013 Jason O'Neil
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
* 
****/

package dtx.collection;

#if !js using dtx.XMLWrapper; #end

class Traversing
{
	/** Return a new collection of all child nodes of the current collection. */
	static public function children(query:Nodes, ?elementsOnly = true)
	{
		var children:Nodes = [];
		if (query != null)
		{
			for (node in query)
			{
				if (dtx.single.ElementManipulation.isElement(node))
				{
					// Add any child elements
					children.addCollection(node.children, elementsOnly);
				}
			}
		}
		return children;
	}

	/** Gets the direct parents of each element in the collection. */
	static public function parent(query:Nodes)
	{
		var parents:Nodes = [];
		if (query != null)
		{
			for (node in query)
			{
				if (node.parentNode != null && node != Detox.document)
					#if js
						parents.add(node.parentNode);
					#else 
						parents.add(node.parent);
					#end
			}
		}
		return parents;
	}

	/** This is identical to parents() but it's necessary to use this on non 
	JS platforms if you want to have null-safety etc. */
	static inline public function parents(query:Nodes)
	{
		return parent(query);
	}

	/** Gets all parents of the current collection, and is called recursively to get all ancestors. */
	static public function ancestors(query:Nodes):Nodes
	{
		// start with the direct parents
		var ancestorList = parent(query);
		
		// If there is at least one parent
		// Then recurse and add all ancestors of that parent
		if (ancestorList.length > 0)
		{
			ancestorList.addCollection(ancestors(ancestorList));
		}

		// Then pass the list back up the line...
		return ancestorList;
	}

	/** Gets all parents of the current collection, and is called recursively to get all ancestors. */
	static public function descendants(query:Nodes, ?elementsOnly:Bool = true):Nodes
	{
		var descendantList = new dtx.DOMCollection();

		if (query != null)
		{
			for (node in query)
			{
				var l = dtx.single.Traversing.descendants(node, elementsOnly);
				descendantList.addCollection(l);
			}
		}

		// Then pass the list back up the line...
		return descendantList;
	}

	static public function next(query:Nodes, ?elementsOnly:Bool = true)
	{
		var siblings:Nodes = [];
		if (query != null)
		{
			for (node in query)
			{
				// Get the next sibling
				var sibling = #if js node.nextSibling #else node.nextSibling() #end ;
				
				// If it's not null, but isn't an element, and we want an element,
				// keep going.
				while (sibling != null 
					&& sibling.nodeType != dtx.DOMType.ELEMENT_NODE
					&& elementsOnly )
				{
					sibling = #if js sibling.nextSibling #else sibling.nextSibling() #end;
				}

				// if we found a match, add it to our group
				if (sibling != null) siblings.add(cast sibling);
			}
		}
		return siblings;
	}

	static public function prev(query:Nodes, ?elementsOnly:Bool = true)
	{
		var siblings:Nodes = [];
		if (query != null)
		{
			for (node in query)
			{
				// get the previous sibling
				var sibling = #if js node.previousSibling #else node.previousSibling() #end;

				// If it's not null, but isn't an element, and we want an element,
				// keep going.
				while (sibling != null  
					&& sibling.nodeType != dtx.DOMType.ELEMENT_NODE
					&& elementsOnly)
				{
					sibling = #if js sibling.previousSibling #else sibling.previousSibling() #end;
				}

				// if we found a match, add it to our group
				if (sibling != null) siblings.add(cast sibling);
			}
		}
		return siblings;
	}

	static public function find(query:Nodes, selector:String)
	{
		var newDOMCollection:Nodes = [];
		if (query != null && selector != null && selector != "")
		{
			for (node in query)
			{
				if (dtx.single.ElementManipulation.isElement(node) || dtx.single.ElementManipulation.isDocument(node))
				{
					#if js
						var element:Element = cast node;
						if (untyped __js__("document.querySelectorAll"))
						{
							var results = element.querySelectorAll(selector);
							newDOMCollection.addNodeList(results);
						}
						else 
						{
							var engine:String->DOMNode->Array<DOMNode> = untyped __js__("
								(('undefined' != typeof Sizzle && Sizzle) || 
								(('undefined' != typeof jQuery) && jQuery.find) || 
								(('undefined' != typeof $) && $.find))
							");
							var results = engine(selector, node);
							newDOMCollection.addCollection(results);
						}
					#elseif !macro
						// This next line is a workaround to a bug in selecthxml
						// See http://code.google.com/p/selecthxml/issues/detail?id=2
						// And http://code.google.com/p/selecthxml/issues/detail?id=3
						var results = selecthxml.SelectDom.runtimeSelect(node, selector);

						// SelectHxml also includes our original node in the search.
						// We should match the querySelectorAll() functionality from JS, which
						// only searches descendant nodes.  Therefore, remove the current node
						// if it was returned as a match.
						results.remove(node);
						
						newDOMCollection.addCollection(results);
					#else 
						throw "Sorry, our selector engine doesn't currently work in macros, so you can't use find()";
					#end
				}
			}
		}
		return newDOMCollection;
	}
}