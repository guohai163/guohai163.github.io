---
layout: post
title:  "Tomcat源码学习笔记"
date:   2014-11-28 14:59:06
categories: [operations]
tags: [tomcat, source, code]
---

###好的习惯###
1. 细化你的注释，甚至可以把流程图也用ASCII的方式写在代码中。例一个接口的注释：


		/*
		 * Licensed to the Apache Software Foundation (ASF) under one or more
		 * contributor license agreements.  See the NOTICE file distributed with
		 * this work for additional information regarding copyright ownership.
		 * The ASF licenses this file to You under the Apache License, Version 2.0
		 * (the "License"); you may not use this file except in compliance with
		 * the License.  You may obtain a copy of the License at
		 *
		 *      http://www.apache.org/licenses/LICENSE-2.0
		 *
		 * Unless required by applicable law or agreed to in writing, software
		 * distributed under the License is distributed on an "AS IS" BASIS,
		 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
		 * See the License for the specific language governing permissions and
		 * limitations under the License.
		 */
		package org.apache.catalina;
		
		
		/**
		 * Common interface for component life cycle methods.  Catalina components
		 * may implement this interface (as well as the appropriate interface(s) for
		 * the functionality they support) in order to provide a consistent mechanism
		 * to start and stop the component.
		 * <br>
		 * The valid state transitions for components that support {@link Lifecycle}
		 * are:
		 * <pre>
		 *            start()
		 *  -----------------------------
		 *  |                           |
		 *  | init()                    |
		 * NEW -»-- INITIALIZING        |
		 * | |           |              |     ------------------«-----------------------
		 * | |           |auto          |     |                                        |
		 * | |          \|/    start() \|/   \|/     auto          auto         stop() |
		 * | |      INITIALIZED --»-- STARTING_PREP --»- STARTING --»- STARTED --»---  |
		 * | |         |                                                  |         |  |
		 * | |         |                                                  |         |  |
		 * | |         |                                                  |         |  |
		 * | |destroy()|                                                  |         |  |
		 * | --»-----«--       auto                    auto               |         |  |
		 * |     |       ---------«----- MUST_STOP ---------------------«--         |  |
		 * |     |       |                                                          |  |
		 * |    \|/      ---------------------------«--------------------------------  ^
		 * |     |       |                                                             |
		 * |     |      \|/            auto                 auto              start()  |
		 * |     |  STOPPING_PREP ------»----- STOPPING ------»----- STOPPED ----»------
		 * |     |                                ^                  |  |  ^
		 * |     |               stop()           |                  |  |  |
		 * |     |       --------------------------                  |  |  |
		 * |     |       |                                  auto     |  |  |
		 * |     |       |                  MUST_DESTROY------«-------  |  |
		 * |     |       |                    |                         |  |
		 * |     |       |                    |auto                     |  |
		 * |     |       |    destroy()      \|/              destroy() |  |
		 * |     |    FAILED ----»------ DESTROYING ---«-----------------  |
		 * |     |                        ^     |                          |
		 * |     |     destroy()          |     |auto                      |
		 * |     --------»-----------------    \|/                         |
		 * |                                 DESTROYED                     |
		 * |                                                               |
		 * |                            stop()                             |
		 * ----»-----------------------------»------------------------------
		 *
		 * Any state can transition to FAILED.
		 *
		 * Calling start() while a component is in states STARTING_PREP, STARTING or
		 * STARTED has no effect.
		 *
		 * Calling start() while a component is in state NEW will cause init() to be
		 * called immediately after the start() method is entered.
		 *
		 * Calling stop() while a component is in states STOPPING_PREP, STOPPING or
		 * STOPPED has no effect.
		 *
		 * Calling stop() while a component is in state NEW transitions the component
		 * to STOPPED. This is typically encountered when a component fails to start and
		 * does not start all its sub-components. When the component is stopped, it will
		 * try to stop all sub-components - even those it didn't start.
		 *
		 * MUST_STOP is used to indicate that the {@link #stop()} should be called on
		 * the component as soon as {@link #start()} exits. It is typically used when a
		 * component has failed to start.
		 *
		 * MUST_DESTROY is used to indicate that the {@link #destroy()} should be called on
		 * the component as soon as {@link #stop()} exits. It is typically used when a
		 * component is not designed to be restarted.
		 *
		 * Attempting any other transition will throw {@link LifecycleException}.
		 *
		 * </pre>
		 * The {@link LifecycleEvent}s fired during state changes are defined in the
		 * methods that trigger the changed. No {@link LifecycleEvent}s are fired if the
		 * attempted transition is not valid.
		 *
		 * TODO: Not all components may transition from STOPPED to STARTING_PREP. These
		 *       components should use MUST_DESTROY to signal this.
		 *
		 * @author Craig R. McClanahan
		 */
		public interface Lifecycle {

2. 枚举enum可以携带多个属性。例：

		/**
		 * The list of valid states for components that implement {@link Lifecycle}.
		 * See {@link Lifecycle} for the state transition diagram.
		 */
		public enum LifecycleState {
		    NEW(false, null),
		    INITIALIZING(false, Lifecycle.BEFORE_INIT_EVENT),
		    INITIALIZED(false, Lifecycle.AFTER_INIT_EVENT),
		    STARTING_PREP(false, Lifecycle.BEFORE_START_EVENT),
		    STARTING(true, Lifecycle.START_EVENT),
		    STARTED(true, Lifecycle.AFTER_START_EVENT),
		    STOPPING_PREP(true, Lifecycle.BEFORE_STOP_EVENT),
		    STOPPING(false, Lifecycle.STOP_EVENT),
		    STOPPED(false, Lifecycle.AFTER_STOP_EVENT),
		    DESTROYING(false, Lifecycle.BEFORE_DESTROY_EVENT),
		    DESTROYED(false, Lifecycle.AFTER_DESTROY_EVENT),
		    FAILED(false, null),
		    MUST_STOP(true, null),
		    MUST_DESTROY(false, null);
		
		    private final boolean available;
		    private final String lifecycleEvent;
		
		    private LifecycleState(boolean available, String lifecycleEvent) {
		        this.available = available;
		        this.lifecycleEvent = lifecycleEvent;
		    }
		
		    /**
		     * May the public methods other than property getters/setters and lifecycle
		     * methods be called for a component in this state? It returns
		     * <code>true</code> for any component in any of the following states:
		     * <ul>
		     * <li>{@link #STARTING}</li>
		     * <li>{@link #STARTED}</li>
		     * <li>{@link #STOPPING_PREP}</li>
		     * <li>{@link #MUST_STOP}</li>
		     * </ul>
		     */
		    public boolean isAvailable() {
		        return available;
		    }
		
		    /**
		     *
		     */
		    public String getLifecycleEvent() {
		        return lifecycleEvent;
		    }
		}

3. 访问外部文件时考虑增加调用耗时纪录。例：

	    /**
	     * Create and configure the Digester we will be using for startup.
	     */
	    protected Digester createStartDigester() {
	        long t1=System.currentTimeMillis();
			Digester digester=new Digester();
			//耗时操作
	        long t2=System.currentTimeMillis();
	        if (log.isDebugEnabled()) {
	            log.debug("Digester for server.xml created " + ( t2-t1 ));
	        }
	        return (digester);
	
	    }

4. 加载文件方法

	    /**
	     * Return a File object representing our configuration file.
	     */
	    protected File configFile() {
	
	        File file = new File(configFile);
	        if (!file.isAbsolute()) {
	            file = new File(Bootstrap.getCatalinaBase(), configFile);
	        }
	        return (file);
	
	    }


###参考资料###
* [直接话ascii流程图](http://www.asciiflow.com/)