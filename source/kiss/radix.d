
module huntlabs.radix;

import std.stdio;
import core.memory;
import core.stdc.string;
import core.stdc.stdlib;


private:

version(DEBUG_LOG){
	import huntlabs.common.Log;
}else{
	void debug_log( A ...)( A args){
		return;
	}
	alias log_info = debug_log;
	alias log_error = debug_log;
}

struct raxNode
{
	uint args;
			  //	1 	iskey	
			  //	1	isnull	don't store it 
			  //	1	iscompr 
			  //	29	size

	//void *data;

	//	node is not compr
	//  [abc][a-ptr][b-ptr][c-ptr](value-ptr?)
	//	
	//  node is compr
	//	[xyz][z-ptr](value-ptr?)
pragma(inline, true):

	@property char *str()
	{
		return cast(char*)(&this + 1);
	}

	@property  bool iskey()
	{
		return cast(bool)(args & 0x80000000);
	}
	
	 @property bool iskey(bool value)
	{
		if(value)
			args = args | 0x80000000;
		else
			args = args & (~0x80000000);

		return value;
	}

	@property bool isnull()
	{
		return cast(bool)(args & 0x40000000);
	}
	
	@property bool isnull( bool value)
	{
		if(value)
			args = args| 0x40000000;
		else
			args = args & (~0x40000000);

		return value;
	}

	@property bool iscompr()
	{
		return cast(bool)(args & 0x20000000);
	}
	
	@property bool iscompr( bool value)
	{
		if(value)
			args = args | 0x20000000;
		else
			args = args & (~0x20000000);
		
		return value;
	}



	
	 @property uint size()
	{
		return args & 0x1FFFFFFF;
	}

	 @property uint size(uint value)
	{
		uint v = args & (~0x1FFFFFFF);
		v += value;
		args = v;
		return value;
	}

	@property raxNode** orgin()
	{
		return cast(raxNode**)(str+size);
	}

	@property raxNode * next()
	{
		return *orgin;
	}

	@property raxNode *next(raxNode *n)
	{
		*orgin = n;
		return n;
	}




	@property raxNode * nextChild(uint index)
	{
		if(index >= size)
			log_error( index , " " , size);
		return orgin[index];
	}

	@property raxNode *nextChild(uint index , raxNode *n)
	{
		orgin[index] = n;
		return n;
	}



	@property void *value()
	{
		if(iscompr)
			return orgin[1];
		else
			return orgin[size];
	}


	@property void * value(void *v)
	{
		if(iscompr)
			orgin[1] = cast(raxNode *)v;
		else
			orgin[size] = cast(raxNode *)v;
		return v;
	}




pragma(inline, false):
	//alloc non-compr node
	static raxNode* New(uint children , bool hasdata)
	{

		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void*).sizeof;

		raxNode *n = cast(raxNode*)malloc(cast(size_t)nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = false;
		n.size = children;

		return n;
	}

	static raxNode *NewComp(uint length , bool hasdata)
	{

		long nodesize = raxNode.sizeof + length + (raxNode *).sizeof;
		if(hasdata)
			nodesize += (void *).sizeof;

		raxNode *n = cast(raxNode*)malloc(cast(size_t)nodesize);
		if( n == null) return null;

		n.iskey = false;
		n.isnull = false;
		n.iscompr = true;
		n.size = length;


		return n;

	}


	static raxNode *Renew(raxNode *n , uint children , bool hasdata)
	{
		long nodesize = raxNode.sizeof + children + (raxNode*).sizeof * children;
		if(hasdata)
			nodesize += (void *).sizeof;


		auto node = cast(raxNode*)realloc(n ,cast(size_t) nodesize);
		if(node == null) return null;
		node.iscompr = false;
		return node;
	}


	static raxNode *RenewComp(raxNode *n , uint length , bool hasdata)
	{

		long nodesize= raxNode.sizeof + length + (raxNode*).sizeof * length;
		if(hasdata)
			nodesize += (void *).sizeof;
	
		auto node = cast(raxNode*) realloc(n , cast(size_t)nodesize);
		if( node == null) return null;
		node.iscompr = true;
		return node;
	}

	static void Free(raxNode *n)
	{
		free(n);
	}




}

struct raxItem
{
	raxNode *n;
	int		index;
}


public:

struct rax
{
	protected 	raxNode 	*head;
	protected	long		numnodes;
	long	 	numele;

	//
	//	api New
	//
	static rax * New()
	{
		rax *r = cast(rax *)malloc(rax.sizeof);
		if (r == null) return null;
		
		r.numele = 0;
		r.numnodes = 1;
		r.head = raxNode.NewComp(0 , false);

		if (r.head == null)
		{
			Free(r);
			return null;
		}
		else
		{
			return r;
		}
	}





	//
	//	api Free
	//
	static void Free(rax *r)
	{
		r.RecursiveFree(r.head);
		free(r);
	}

	//
	//	api Clear
	//
	void Clear(){

		RecursiveFree(head);

		numele = 0;
		numnodes = 1;
		head = raxNode.NewComp(0 , false);

	}

	//
	//	api Remove
	//
	bool Remove(const ubyte[] s)
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem[] ts;
		uint index = 0;
		uint splitpos = 0;
		uint last = find(s , h , p , index , splitpos , ts);
		if(last > 0){
			log_error("remove " , cast(string)s , " " ,last);
			return false;
		}
		else{
			if(h.iskey) {
				numele--;
				h.iskey = false;
				if(h.size == 0)
				{

					if( p.iscompr)
					{
						//#1	最后一个节点为空	父节点压缩节点 且是key 则去除父节点			
						//		   (x)
						//			|			- 'test'       (x)
						//		('test')	------------->		|
						//			|							()
						//			()
						//

						if(p.iskey)
						{
							h.iskey = true;
							h.value = p.value;
							if(p == head)
							{
								head = h;
							
							}
							else
							{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , h);
							}
							numnodes -= 1;
							raxNode.Free(p);
							log_info("#####r1");
						}
						//#2	最后一个节点为空	父节点是压缩节点 不是key 父父节点必须是非压缩节点  
						//		   (t)
						//			|
						//		   (A)
						//			|
						//		  ['xyz']
						//		   /  \				- 'test'
						//		 (B)	('test')  ---------------->	
						//    	  |		|			
						//		 (C)   ()
						//
						//
						//		#1  当['xy']	 size == 2
						//				#1 当['xy']不是key，A为压缩节点 && 当B为压缩节点 且不是key,合并三项
						//		   (t)
						//			|
						//		   (A)
						//			|
						//		  ['xy']
						//		   /  \				- 'test'				(t)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								(A + 'x' + B)
						//		 (C)   ()									|
						//													(C)
						//
						//				#2 当['xy']不是key，A为压缩节点 , 合并两项
						//		   (t)
						//			|
						//		   (A)
						//			|										
						//		  ['xy']									
						//		   /  \				- 'test'				(t)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								( A  + 'x')
						//		 (C)   ()									|
						//													(B)
						//													|
						//													(C)
						//
						//				#3 当B为压缩节点 且不是key ， 合并两项
						//		   (t)
						//			|
						//		   (A)
						//			|										(t)
						//		  ['xy']									|
						//		   /  \				- 'test'				(A)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								( 'x' + B)
						//		 (C)   ()									|
						//													(C)
						//
						//				#4 当都不能合并时
						//		   (t)
						//			|
						//		   (A)
						//			|										(t)
						//		  ['xy']									|
						//		   /  \				- 'test'				(A)
						//		 (B)	('test')  ---------------->			|
						//    	  |		|								  ( 'x')
						//		 (C)   ()									|
						//													(B)
						//													|
						//													(C)
						else // pp exist. & pp is non compr
						{
							//pp
							if( p == head)
							{
								head = h;
								numnodes -= 1;
								log_info("#####r2");
							}
							else{
								raxItem t1 = ts[$ - 2];
								raxNode *r1 = ts[$ - 2].n;
								if( r1.size == 2){
								
									raxNode *pp = null;
									if(ts.length >= 3)
										pp = ts[$ - 3].n;
									bool ppCombine =  pp && pp.iscompr && !r1.iskey;
									raxNode *nh = r1.nextChild(r1.size - 1 - t1.index);
									bool nhCombie = nh.iscompr && !nh.iskey;



									if( ppCombine && nhCombie)
									{
										bool hasdata = pp.iskey && !pp.isnull;
										raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

										u.iskey = pp.iskey;
										if(hasdata)
										{
											u.value = pp.value;
										}
										u.next( nh.next);
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 4;
										log_info("#####r211");

									}
									else if(ppCombine)
									{
										bool hasdata = pp.iskey && !pp.isnull;
										raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
										memcpy(u.str , pp.str , pp.size);
										memcpy(u.str + pp.size , r1.str+ r1.size - 1 - t1.index , 1);
										u.next(nh);
										u.iskey = pp.iskey;
										if(hasdata)
										{
											u.value = pp.value;
										}
										
										if( pp == head)
										{
											head = u;
										}
										else{
											raxItem item = ts[$ - 4];
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(pp);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										
										log_info("#####r212");
									}
									else if(nhCombie)
									{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode* u = raxNode.NewComp(1 + nh.size , hasdata);
										memcpy(u.str  , r1.str + r1.size - 1 - t1.index , 1);
										memcpy(u.str + 1,  nh.str , nh.size);
										u.iskey = r1.iskey;

										if(hasdata)
										{
											u.value = r1.value;
										}

										u.next(nh.next);

										
										if( r1 == head)
										{
											head = u;
										}
										else
										{
											raxItem item = ts[$ - 3];
											log_info(getStr(item.n));
											item.n.nextChild(item.index , u);
										}
										raxNode.Free(nh);
										raxNode.Free(p);
										raxNode.Free(h);
										raxNode.Free(r1);
										numnodes -= 3;
										log_info("#####r213");
									}
									else{
										bool hasdata = r1.iskey && !r1.isnull;
										raxNode *n = raxNode.NewComp(1 , hasdata);
										n.iskey = r1.iskey;
										if(hasdata)
											n.value = r1.value;
										n.str[0] = r1.str[r1.size - 1 - t1.index];
										n.next( r1.nextChild(r1.size - 1 - t1.index));
										
										if(r1 == head)
										{
											head = n;
										}
										else{
											raxItem item = ts[$ - 3];
											item.n.nextChild(item.index , n);
										}
										
										raxNode.Free(h);
										raxNode.Free(p);
										raxNode.Free(r1);
										numnodes -= 2;
										log_info("#####r214");
									}


								}
								//		#1  当['xyz'] 的size > 2
								//				
								//		   (t)										(t)
								//			|										 |
								//		   (A)										(A)
								//			|										 |
								//		  ['xyz']                                   ['xz']
								//		   /  \    \ 				- 'test'	    /   \
								//		 (B)('test') (D)  ---------------->		  ('B')   (D)
								//    	  |		|								
								//		 (C)   ()									
								//													
								else if (r1.size > 2){

									bool hasdata = r1.iskey && !r1.isnull;
									raxNode *u = raxNode.New(r1.size - 1, hasdata);
									u.iskey = r1.iskey;
									if(hasdata)
									{
										u.value = r1.value;
									}
									
									log_info("index " , t1.index , " " , r1.size);
									
									if( t1.index == 0)
									{
										memcpy(u.str , r1.str + 1 , r1.size - 1 );

									}
									else if(t1.index == r1.size - 1)
									{	
										memcpy(u.str , r1.str , r1.size - 1);
									}
									else
									{
										memcpy(u.str , r1.str  , t1.index);
										memcpy(u.str + t1.index  , r1.str + t1.index + 1, r1.size - t1.index -1);
									}

									log_info(getStr(u));

									for( uint i , j  = 0 ; i < r1.size ; )
									{
										if( i != t1.index)
											u.orgin[j++] = r1.orgin[i++];
										else
											i++;
									}

									//raxNode *test = null;

									if(r1 == head)
									{
										head = u;
									}
									else{
										raxItem i = ts[$ - 3];
										
										i.n.nextChild(i.index , u);
										
									}
									
									raxNode.Free(r1);
									raxNode.Free(h);
									raxNode.Free(p);
				
									numnodes -= 2;
									log_info("####r22");

								}
								else{
									log_error("####r23 none exist");
								}
							}
						}
					}
					//	#3  当父节点为非压缩节点
					//
					//
					//			 (A)
					//			  |					A+'y'
					//			['xyz']			----------->
					//			 / |  \
					//			(C) () (D)
					//
					//
					//
					//		#1 当['xy'] 的size == 2时
					//				
					//				当#1 ['xy']非key，且(C)非key , 合并三项
					//			 (t)
					//			  |
					//			 (A)
					//			  |					A+'y'			   (t)
					//			['xy']			----------->      	 	|
					//			 / |								(A + 'x' + C)
					//			(C) () 									|
					//			 |										(D)
					//			(D)		
					//
					//		
					//				
					//				当#2 ['xy']非key , 合并两项
					//			 (t)
					//			  |
					//			 (A)
					//			  |					A+'y'			   (t)
					//			['xy']			----------->      	 	|
					//			 / |								(A + 'x' )
					//			(C) () 									|
					//			 |										(C)
					//			(D)										|
					//													(D)
					//				当#3 (C)非key , 合并两项
					//			 (t)
					//			  |									   (t)
					//			 (A)								    |
					//			  |					A+'y'			   (A)
					//			['xy']			----------->      	 	|
					//			 / |								('x' + C)
					//			(C) () 									|
					//			 |										(D)
					//			(D)	
					//
					//			   当#4 无合并
					//											
					//			 (t)
					//			  |									   (t)
					//			 (A)								    |
					//			  |					A+'y'			   (A)
					//			['xy']			----------->      	 	|
					//			 / |								  ('x')
					//			(C) () 									|
					//			 |										(C)
					//			(D)										|	
					//													(D)
					else if(!p.iscompr)
					{
						// noncompr to compr
						log_info("p " , getStr(p));
						if(p.size == 2){
						
								raxNode *pp = null ;
								if(ts.length >= 2)
									pp = ts[$ - 2].n;
								bool ppCombine = pp && pp.iscompr && !p.iskey;
								raxNode *nh = p.nextChild(p.size - 1 - index);

								log_info("nh " , getStr(nh));
								bool nhCombie = nh.iscompr && !nh.iskey;
								
								log_info(ppCombine , " " , nhCombie);
								
								// #1 合并3个
								if( ppCombine && nhCombie)
								{
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + nh.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str + p.size - 1 - index , 1);
									memcpy(u.str + pp.size + 1 , nh.str ,  nh.size);

									u.iskey = pp.iskey;	
									if(hasdata)
										u.value = pp.value;

									u.next( nh.next);
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);

									numnodes -= 3;

									log_info("#####r311");
								}
								// #2 
								else if(ppCombine)
								{
									
									bool hasdata = pp.iskey && !pp.isnull;
									raxNode *u = raxNode.NewComp(pp.size + 1 , hasdata);
									memcpy(u.str , pp.str , pp.size);
									memcpy(u.str + pp.size , p.str+ p.size - 1 - index , 1);
									u.next(nh);
									u.iskey = pp.iskey;
									if(hasdata)
										u.value = pp.value; 
									
									if( pp == head)
									{
										head = u;
									}
									else{
										raxItem item = ts[$ - 3];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(pp);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;

									log_info("#####r312");
								}
								else if(nhCombie)
								{
									bool hasdata = p.iskey && !p.isnull;
									raxNode* u = raxNode.NewComp(1 + nh.size , hasdata);
									memcpy(u.str  , p.str + p.size - 1 - index , 1);
									memcpy(u.str + 1,  nh.str , nh.size);
									u.iskey = p.iskey;
									u.next(nh.next);
									if(hasdata)
										u.value = p.value;
									if( p == head)
									{
										head = u;
									}
									else
									{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , u);
									}
									raxNode.Free(nh);
									raxNode.Free(p);
									raxNode.Free(h);
									numnodes -= 2;
									log_info("#####r313");
								}
								// p.iskey or no combine.
								else{
									bool hasdata = p.iskey && !p.isnull;
									raxNode *n = raxNode.NewComp(1 , hasdata);
									n.iskey = p.iskey;
									if(hasdata)
										n.value = p.value;
									n.str[0] = p.str[p.size - 1 - index];
									n.next( p.nextChild(p.size - 1 - index));
									
									if(p == head)
									{
										head = n;
									}
									else{
										raxItem item = ts[$ - 2];
										item.n.nextChild(item.index , n);
									}
									
									raxNode.Free(h);
									raxNode.Free(p);
									numnodes -= 1;
									log_info("#####r314");
							}

						}
						//		#2 当['xyz'] 的size > 2时
						//			 (A)								(A)
						//			  |					A+'y'			 |
						//			['xyz']			----------->		['xz']
						//			 / |  \								/ \
						//			(C) () (D)						  (C) (D)
						//
						//
						//

						else if(p.size > 2){

							bool hasdata = p.iskey && !p.isnull;
							raxNode *u = raxNode.New(p.size - 1, hasdata);
							u.iskey = p.iskey;
							if(hasdata)
							{
								u.value = p.value;
							}

							log_info("index " , index , " " , p.size);
						
							if( index == 0)
							{
								memcpy(u.str , p.str + 1 , p.size - 1 );
							}
							else if(index == p.size - 1)
							{	
								memcpy(u.str , p.str , p.size - 1);
							}
							else
							{
								memcpy(u.str , p.str  , index);
								memcpy(u.str + index  , p.str + index + 1, p.size - index -1);
							}

							for( uint i , j  = 0 ; i < p.size ; )
							{
								if( i != index)
									u.orgin[j++] = p.orgin[i++];
								else
									i++;
							}

							if(p == head)
							{
								head = u;
							}
							else{
								raxItem item = ts[$ - 2];
								item.n.nextChild(item.index , u);
							}


							raxNode.Free(h);
							raxNode.Free(p);
							numnodes--;
							log_info("#####r32");
						}
					}
				}
				// h.size > 0
				else{
					//	#4 节点是压缩节点 ， 则合并
					//			  (A)								(A + 'test')
					//				|								 	|
					//			('test')		- 'test'				(B)
					//			   |
					//			  (B)		----------->      
					//
					//
					//	#5 只是去掉一个值。

					if(h.iscompr && p.iscompr)
					{
						bool hasdata = p.iskey && !p.isnull;
						raxNode *u = raxNode.NewComp(p.size + h.size ,  hasdata);
						u.iskey = p.iskey;
						if(hasdata)
						{
							u.value = p.value;
						}

						memcpy(u.str , p.str , p.size);
						memcpy(u.str + p.size , h.str , h.size);
						u.next(h.next);
						if(p == head)
						{
							head = u;
						}
						else
						{
							raxItem item = ts[$ - 2];
							item.n.nextChild(item.index , u);
						}
						numnodes--;
						raxNode.Free(p);
						raxNode.Free(h);
						log_info("#####r4");
					}
					else{
						log_info("#####r5");
					}

				}
				return true;			
			}
			else{
				log_error(cast(string)s , " is not key " , getStr(h));
				return false;
			}
		}
	
	}

	//
	//	api Insert
	//
	int Insert(const ubyte[] s , void *data )
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem [] ts;
		uint index = 0;
		uint splitpos = 0;
		numele++;
		uint last = find(s , h , p , index , splitpos , ts);

		log_info("find " ,cast(string)s , " last ",  last , " split " , splitpos ," index " , index);

		//没有找到该s.
		if (last > 0)
		{
			// #1 如果该树是空树.
			//
			//				'test'
			//		（） ----------->（'test'）
			//							 |	
			//							()
			//							
			if(p.size == 0)
			{
				raxNode *n = raxNode.NewComp(cast(uint)s.length , false);
				memcpy(n.str , s.ptr , s.length);

				p = raxNode.RenewComp(p , 0 , true);
				p.iskey = true;
				p.value = data;

				n.next = p;
				head = n;

				numnodes++;

				log_info("####1");
				return 1;
			}
			else
			{
					
					// #2 直到匹配到叶子节点，都没有匹配到，必须往该叶子节点后面加剩余的字符。
					//				'tester'
					//	("test") -------->	("test")
					//		|					|
					//		()				  ("er")
					//							|
					//							()
					if(h.size == 0)
					{
						//1 new comp node
						raxNode *n = raxNode.NewComp(last , true);
						memcpy(n.str , s[ $ - last .. $].ptr , last);
						n.iskey = true;
						n.value = h.value;
						
						h.value = data;
			
						n.next = h;
						p.nextChild(index , n);
			
						numnodes++;

						log_info("####2");
						return 1;
					}
					//	#3	匹配到压缩节点，1 必须截断前部分。2 取原字符及压缩节点匹配字符构成 两个字符的 非压缩节点。 
					//			3 非压缩节点 两个子节点 分别指向 截断后半部分 及 原字符后半部分
					//
					//				'teacher'
					//	('test')---------------->('te')
					//		|						|
					//		(x)					  ['as']	u2
					//							   / \	
					//					u4 ('cher')  ('t') u3
					//						   /		\
					//					  u5 ()			(x)
					//
					else if(h.iscompr) {

						raxNode *u1;

						bool hasvalue = h.iskey && !h.isnull;
						auto u2 = raxNode.New(2 , hasvalue && splitpos <= 0);
						u2.str[0] = s[$ - last];
						u2.str[1] = h.str[splitpos];
						numnodes++;

						
						if( splitpos > 0)
						{
							u1 = raxNode.NewComp(splitpos , hasvalue);
							memcpy(u1.str , h.str , splitpos);
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
							numnodes++;
						}
						else{
							u1 = u2;
							u1.iskey = h.iskey;
							if(hasvalue)
								u1.value = h.value;
						}


						uint u3_len = h.size - splitpos - 1;
						raxNode *u3;
						bool bcombine = false;
						if( u3_len > 0 )
						{
							//combin
							if(h.next.size > 0 && h.next.iscompr && !h.next.iskey)
							{
								u3 = raxNode.NewComp(u3_len + h.next.size , h.next.iskey && !h.next.isnull);
								memcpy(u3.str , h.str + splitpos + 1 , h.size - splitpos -1);
								memcpy(u3.str + h.size - splitpos - 1 , h.next.str , h.next.size);
								numnodes++;
								bcombine = true;

							}
							else
							{
								u3 = raxNode.NewComp(h.size - splitpos - 1 , false);
								memcpy(u3.str , h.str + splitpos + 1 ,h.size - splitpos -1);
								numnodes++;
							}
						}
						else
						{
							u3 = h.next;
						}
						

						//4
						uint u4_len = last - 1;
						raxNode *u4;
						
						//5
						auto u5 = raxNode.NewComp(0 , true);
						u5.iskey = true;
						u5.value = data;
						numnodes++;

						if(u4_len > 0)
						{		
							u4 = raxNode.NewComp(last - 1, false);
							memcpy(u4.str  , s.ptr + s.length - last + 1 , last - 1);
							numnodes++;
						}
						else{
							u4 = u5;
						}
						
						//relation
						if(u4_len > 0)
							u4.next = u5;

						if(bcombine)
						{
							u3.next = h.next.next;
							raxNode.Free(h.next);
							numnodes--;
						}
						else if( u3_len > 0)
						{
							u3.next = h.next;
						}	 	

						u2.nextChild(0 , u4);
						u2.nextChild(1 , u3);
						
						if(splitpos > 0)
							u1.next = u2;

						p.nextChild(index , u1);

						if( h == head)
							head = u1;
							
						raxNode.Free(h);
						numnodes--;
						
						log_info("####3");
						return 1;

				}
				// 	#4	都不匹配非压缩节点的任何子节点 1 增加该字符 2 截断原字符
				//	
				//					 'beer'				
				//			["tes"]	--------->	['tesb']
				//			/ / \ 				/ / \  \
				// 		  () () ()             () () () ('eer')
 				//											\
				//											()
				else{	

					bool hasdata = !h.isnull && h.iskey;
					auto i = raxNode.New( h.size + 1 , hasdata);
					i.iskey = h.iskey;
					if(hasdata)
					{
						i.value = h.value;	//modify 
					}

					numnodes++;
					memcpy(i.str ,  h.str, h.size );
					i.str[h.size] = s[$ - last];
					memcpy(i.str + i.size  , h.str + h.size , h.size * (raxNode *).sizeof);


					auto u1_len = last - 1;
					raxNode *u1;


					auto u2 = raxNode.NewComp(0 , true);
					u2.value = data;
					u2.iskey = true;
					numnodes++;
					if( u1_len > 0)
					{
						u1 = raxNode.NewComp(u1_len , false);
						memcpy(u1.str , s.ptr  + s.length - last + 1  , u1_len);
						numnodes++;
						u1.next = u2;
					}
					else
					{
						u1 = u2;
					}

					i.nextChild(h.size , u1);
					p.nextChild(index , i);

					if(h == head)
						head = i;
					raxNode.Free(h);
					numnodes--;
					log_info("####4");
					return 1;
				}
			}

		}else{
			//	#5	完全匹配，只要改个值 即可。
			//							'te'
			//				('te')	------------->	 the same
			//				  |
			//				['as']
			//				 /  \
			//		  ('cher')  ('t')
			//			 |		  |
			//			()		 ()
			if(splitpos == 0)
			{
				bool hasdata = (h.iskey && !h.isnull);
				if(hasdata) {
					
					h.value = data;
					if(h.iskey)		//replaced
						numele--;
					else
						assert(0);

					log_info("####50");
					return 0;

				}
				else{
					raxNode *u;
					if(h.iscompr)
						u = raxNode.RenewComp(h , h.size , true);
					else
					{
						u = raxNode.Renew(h , h.size ,true);
					}
					u.value = data;
					u.iskey = true;
					p.nextChild(index , u);

					log_info("####51");
					return 1;
				}



			}
			//	#6	完全匹配压缩节点前半部分。 分割即可。
			//					'te'
			//	('test')	--------->		('te')
			//		|						  |
			//	   (x)						('st')
			//								  |
			//								 (x)
			//
			else if(h.iscompr) {


				bool hasdata = (h.iskey && !h.isnull);
				auto u1 = raxNode.NewComp(splitpos , hasdata);
				memcpy(u1.str , h.str , splitpos);
				u1.iskey = h.iskey;
				if(hasdata)
					u1.value = h.value;
				numnodes++;
			
				auto u2 = raxNode.NewComp(h.size - splitpos , true);
				memcpy(u2.str , h.str + splitpos , h.size - splitpos);
				u2.iskey = true;
				u2.value = data;
				numnodes++;
				u2.next = h.next;


				u1.next = u2;

				raxNode.Free(h);
				numnodes--;
				if(h == head)
				{
					head = u1;
				}
				else{
					p.nextChild(index , u1);
				}

				log_info("####6");
				return 1;
			}else{
				writeln("assert");
				assert(0);
			}
		}

	}

	//
	//	api find
	//
	bool find(const ubyte[] s , out void *data)
	{
		raxNode *h = head;
		raxNode *p = head;
		raxItem [] ts;
		uint index = 0;
		uint splitpos = 0;
		uint last = find(s , h , p , index , splitpos , ts);
		if(last == 0 && splitpos == 0 && h.iskey)
		{
			data = h.value;
			return true;
		}

		return false;
	}

private:

	void RecursiveFree(raxNode *n)
	{
		int numchildren = 0;
		if(n.iscompr)
		{
			numchildren = n.size > 0 ? 1: 0;
		}
		else
		{
			numchildren = n.size;
		}
		while(numchildren--){
			RecursiveFree(n.nextChild(numchildren));  
		}
		raxNode.Free(n);
		numnodes--;
	}


	//find
	uint find(const ubyte[] s , ref raxNode *r , ref raxNode *pr , ref uint index  , ref uint splitpos ,ref raxItem[] ts)
	{
		//find it

		if ( s == null)
		{	
			return 0;
		}

		if( r.size == 0)
		{	
			return cast(uint)s.length;
		}
			
		if ( r.iscompr )	//is compr
		{
			char *p = r.str;
			uint i = 0;
			for( i = 0 ; i < r.size && i < s.length ; i++)
			{
				if(p[i] != s[i])
					break;
			}


			if( i == r.size)
			{	
				pr = r;
				r = r.next;
				index = 0;
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[(*pr).size .. $] , r , pr, index , splitpos , ts);
			}
			else 
			{
				splitpos = i;
				return cast(uint)s.length - i;
			}
		}
		else {

			char *p = r.str;
			char *end = r.str + r.size;
			while(p != end)
			{
				if( *p == s[0])
					break;
				p++;
			}


			uint i = cast(uint)(p - r.str);
			if( p == end)
			{	
				splitpos = i;
				return cast(uint)s.length;
			}
			else
			{
				pr = r;
				index = i ;
				r = r.nextChild(index);	
				raxItem item;
				item.n = pr;
				item.index = index;
				ts ~= item;
				return find(s[1 .. $] , r , pr , index , splitpos , ts);
			}
		}

	}

	string getStr(raxNode *h)
	{
		string str;
		for(uint i = 0 ; i < h.size ; i++)
			str ~= h.str[i];
		return str;
	}


	void Recursiveshow(raxNode *n , int level)
	{
	
		show(n , level);

		if(n.size == 0)
			return ;
			
		if(n.iscompr)
		{
			Recursiveshow(n.next , ++level);
		}
		else
		{
			++level;
			for(uint i = 0 ; i < n.size ; i++)
			{	
				Recursiveshow(n.nextChild(i) , level);
			}
		}
	}

	void show(raxNode *n , int level)
	{

		for(uint i = 0 ; i < level ; i++)
			write("\t");
		write(" key:" , n.iskey  , n.iscompr ? " (" : " [");

		for(uint i = 0 ; i < n.size ; i++)
			write(n.str[i]);

		write(n.iscompr ? ") ":"] " ,  (n.iskey && !n.isnull)?n.value:null , "\n");
	}

	void show()
	{
		raxNode *p = head;
		writef("numele:%d numnodes:%d\n" , numele , numnodes);


		Recursiveshow(p ,0);

		writef("\n");
	}





};








unittest{


	void test1()
	{
		string[] toadd = ["alligator","alien","baloon","chromodynamic","romane","romanus","romulus","rubens","ruber","rubicon","rubicundus","all","rub","ba"];
		rax *r = rax.New();
		foreach( i ,s ; toadd)
		{
			r.Insert(cast(ubyte[])s , cast(void *)i);
		}
	
		foreach(s ; toadd)
		{
			r.Remove(cast(ubyte[])s);
		}
		r.show();
	}

	void test2()
	{
		string origin = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                  ~ "abcdefghijklmnopqrstuvwxyz"
			~ "0123456789";
		import std.random;

		string[] keys;
		uint num = 1000;

		for(uint j = 0 ; j < num ; j++)
		{
			uint len = uniform(1 , 16);
			string key;
			for(uint i = 0 ; i < len ; i++)
			{
				size_t index = uniform(0 , origin.length);
				key ~= origin[index];
			}
			keys ~= key;
		}

		rax *r = rax.New();
		foreach(i , k ; keys)
		{
			r.Insert(cast(ubyte[])k , cast(void *)i);
		}


		foreach(k ; keys)
		{
			r.Remove(cast(ubyte[])k);
		}

		r.show();
		assert(r.numele == 0);
	}


}


