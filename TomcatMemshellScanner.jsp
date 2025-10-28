<%@ page import="java.net.URL" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="com.sun.org.apache.bcel.internal.Repository" %>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="org.apache.catalina.core.StandardWrapper" %>
<%@ page import="java.lang.reflect.Method" %>
<%@ page import="java.util.concurrent.CopyOnWriteArrayList" %>
<%@ page import="org.apache.catalina.Pipeline" %>
<%@ page import="org.apache.catalina.Valve" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="org.apache.catalina.connector.Request" %>
<%@ page import="java.util.*" %>
<%@ page import="org.apache.tomcat.websocket.server.WsServerContainer" %>
<%@ page import="javax.websocket.server.ServerEndpointConfig" %>
<%@ page import="javax.websocket.server.ServerContainer" %>
<%@ page import="org.apache.coyote.UpgradeProtocol" %>
<%@ page import="org.apache.coyote.http11.AbstractHttp11Protocol" %>
<%@ page import="org.apache.catalina.connector.Connector" %>
<%@ page import="org.apache.tomcat.util.net.NioEndpoint" %>
<%@ page import="org.apache.tomcat.util.threads.ThreadPoolExecutor" %>
<%@ page import="java.util.concurrent.TimeUnit" %>
<%@ page import="java.io.File" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.net.URISyntaxException" %>
<%@ page import="java.nio.file.attribute.BasicFileAttributes" %>
<%@ page import="java.nio.file.Files" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>TomcatMemshellScanner</title>
</head>
<body>
<center>
    <div>
        <%!
            public Object getStandardContext(HttpServletRequest request) throws NoSuchFieldException, IllegalAccessException {
                Object context = request.getSession().getServletContext();
                Field _context = context.getClass().getDeclaredField("context");
                _context.setAccessible(true);
                Object appContext = _context.get(context);
                Field __context = appContext.getClass().getDeclaredField("context");
                __context.setAccessible(true);
                Object standardContext = __context.get(appContext);
                return standardContext;
            }
            private static Object getField(Object object, String fieldName) throws Exception {
                Field field = null;
                Class clazz = object.getClass();

                while (clazz != Object.class) {
                    try {
                        field = clazz.getDeclaredField(fieldName);
                        break;
                    } catch (NoSuchFieldException var5) {
                        clazz = clazz.getSuperclass();
                    }
                }

                if (field == null) {
                    throw new NoSuchFieldException(fieldName);
                } else {
                    field.setAccessible(true);
                    return field.get(object);
                }
            }
            public HashMap<String, Object> getFilterConfig(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _filterConfigs = standardContext.getClass().getDeclaredField("filterConfigs");
                _filterConfigs.setAccessible(true);
                HashMap<String, Object> filterConfigs = (HashMap<String, Object>) _filterConfigs.get(standardContext);
                return filterConfigs;
            }

            // FilterMap[]
            public Object[] getFilterMaps(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _filterMaps = standardContext.getClass().getDeclaredField("filterMaps");
                _filterMaps.setAccessible(true);
                Object filterMaps = _filterMaps.get(standardContext);

                Object[] filterArray = null;
                try { // tomcat 789
                    Field _array = filterMaps.getClass().getDeclaredField("array");
                    _array.setAccessible(true);
                    filterArray = (Object[]) _array.get(filterMaps);
                } catch (Exception e) { // tomcat 6
                    filterArray = (Object[]) filterMaps;
                }

                return filterArray;
            }

            /**
             * Legacy issue: getFilterConfig() still has 2 instances
             * @param request
             * @param filterName
             * @throws Exception
             */
            public synchronized void deleteFilter(HttpServletRequest request, String filterName) throws Exception {
                Object standardContext = getStandardContext(request);
                // org.apache.catalina.core.StandardContext#removeFilterDef
                HashMap<String, Object> filterConfig = getFilterConfig(request);
                Object appFilterConfig = filterConfig.get(filterName);
                Field _filterDef = appFilterConfig.getClass().getDeclaredField("filterDef");
                _filterDef.setAccessible(true);
                Object filterDef = _filterDef.get(appFilterConfig);
                Class clsFilterDef = null;
                try {
                    // Tomcat 8
                    clsFilterDef = Class.forName("org.apache.tomcat.util.descriptor.web.FilterDef");
                } catch (Exception e) {
                    // Tomcat 7
                    clsFilterDef = Class.forName("org.apache.catalina.deploy.FilterDef");
                }
                Method removeFilterDef = standardContext.getClass().getDeclaredMethod("removeFilterDef", new Class[]{clsFilterDef});
                removeFilterDef.setAccessible(true);
                removeFilterDef.invoke(standardContext, filterDef);

                // org.apache.catalina.core.StandardContext#removeFilterMap
                Class clsFilterMap = null;
                try {
                    // Tomcat 8
                    clsFilterMap = Class.forName("org.apache.tomcat.util.descriptor.web.FilterMap");
                } catch (Exception e) {
                    // Tomcat 7
                    clsFilterMap = Class.forName("org.apache.catalina.deploy.FilterMap");
                }
                Object[] filterMaps = getFilterMaps(request);
                for (Object filterMap : filterMaps) {
                    Field _filterName = filterMap.getClass().getDeclaredField("filterName");
                    _filterName.setAccessible(true);
                    String filterName0 = (String) _filterName.get(filterMap);
                    if (filterName0.equals(filterName)) {
                        Method removeFilterMap = standardContext.getClass().getDeclaredMethod("removeFilterMap", new Class[]{clsFilterMap});
                        removeFilterDef.setAccessible(true);
                        removeFilterMap.invoke(standardContext, filterMap);
                    }
                }
            }

            public synchronized void deleteServlet(HttpServletRequest request, String servletName) throws Exception {
                HashMap<String, Object> childs = getChildren(request);
                Object objChild = childs.get(servletName);
                String urlPattern = null;
                HashMap<String, String> servletMaps = getServletMaps(request);
                for (Map.Entry<String, String> servletMap : servletMaps.entrySet()) {
                    if (servletMap.getValue().equals(servletName)) {
                        urlPattern = servletMap.getKey();
                        break;
                    }
                }

                if (urlPattern != null) {
                    // 反射调用 org.apache.catalina.core.StandardContext#removeServletMapping
                    Object standardContext = getStandardContext(request);
                    Method removeServletMapping = standardContext.getClass().getDeclaredMethod("removeServletMapping", new Class[]{String.class});
                    removeServletMapping.setAccessible(true);
                    removeServletMapping.invoke(standardContext, urlPattern);
                    // Tomcat 6必须removeChild 789可以不用
                    // 反射调用 org.apache.catalina.core.StandardContext#removeChild
                    Method removeChild = standardContext.getClass().getDeclaredMethod("removeChild", new Class[]{org.apache.catalina.Container.class});
                    removeChild.setAccessible(true);
                    removeChild.invoke(standardContext, objChild);
                }
            }
            public synchronized void deleteListener(HttpServletRequest request, String listenerName) throws Exception {
                Object standardContext = getStandardContext(request);
                List<Object> listeners = getListenerList(request);
                List<Object> newListeners = new ArrayList<Object>();
                for (Object listener : listeners) {
                    if (listener.getClass().getName().equals(listenerName)) {
                        continue;
                    }

                    newListeners.add(listener);
                }

                try {
                    Method setListenerList = standardContext.getClass().getMethod("setApplicationEventListeners",
                            Object[].class);
                    setListenerList.invoke(standardContext, new Object[]{newListeners.toArray()});
                } catch (Exception e) {
                    e.printStackTrace();
                }

            }

            public synchronized HashMap<String, Object> getChildren(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _children = standardContext.getClass().getSuperclass().getDeclaredField("children");
                _children.setAccessible(true);
                HashMap<String, Object> children = (HashMap<String, Object>) _children.get(standardContext);
                return children;
            }


            public synchronized HashMap<String, String> getServletMaps(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _servletMappings = standardContext.getClass().getDeclaredField("servletMappings");
                _servletMappings.setAccessible(true);
                HashMap<String, String> servletMappings = (HashMap<String, String>) _servletMappings.get(standardContext);
                return servletMappings;
            }

            public synchronized List<Object> getListenerList(HttpServletRequest request) throws Exception {
                Object standardContext = getStandardContext(request);
                Field _listenersList = standardContext.getClass().getDeclaredField("applicationEventListenersList");
                _listenersList.setAccessible(true);
                List<Object> listenerList = (CopyOnWriteArrayList) _listenersList.get(standardContext);
                return listenerList;
            }

            public String getFilterName(Object filterMap) throws Exception {
                Method getFilterName = filterMap.getClass().getDeclaredMethod("getFilterName");
                getFilterName.setAccessible(true);
                return (String) getFilterName.invoke(filterMap, null);
            }

            public String[] getURLPatterns(Object filterMap) throws Exception {
                Method getFilterName = filterMap.getClass().getDeclaredMethod("getURLPatterns");
                getFilterName.setAccessible(true);
                return (String[]) getFilterName.invoke(filterMap, null);
            }


            String classFileIsExists(Class clazz) {
                String className = clazz.getName();
                String classNamePath = className.replace(".", "/") + ".class";
                URL is = clazz.getClassLoader().getResource(classNamePath);
                if (is == null) {
                    return "not found";
                } else {
                    return is.getPath();
                }

            }

            String arrayToString(String[] str) {
                String res = "[";
                for (String s : str) {
                    res += String.format("%s,", s);
                }
                res = res.substring(0, res.length() - 1);
                res += "]";
                return res;
            }
            public Object getNioEndpoint() throws Exception {
                Thread[] threads = (Thread[]) getField(Thread.currentThread().getThreadGroup(), "threads");
                Field f = ThreadGroup.class.getDeclaredField("threads");
                f.setAccessible(true);
                for (Thread thread: threads) {
                    if (thread.getName().contains("http") && thread.getName().contains("Poller")) {
                        f = Thread.class.getDeclaredField("target");
                        f.setAccessible(true);
                        Object pollor = f.get(thread);
                        f = pollor.getClass().getDeclaredField("this$0");
                        f.setAccessible(true);
                        Object nioEndpoint = (NioEndpoint)f.get(pollor);
                        return nioEndpoint;
                    }
                }
                return new Object();
            }
            public static String judgeClassLocation(Class<?> clazz) {
                try {
                    String classNamePath = clazz.getName().replace('.', '/') + ".class";
                    URL url = clazz.getClassLoader().getResource(classNamePath);

                    if (url == null) {
                        return "<span style='color:orange;'>No class file on disk: likely a memory shell</span>";
                    }

                    String urlStr = url.toString();

                    if (urlStr.contains("/work/") || urlStr.contains(File.separator + "work" + File.separator)) {
                        return "<span style='color:orange;'>Class from work directory: likely a memory shell</span>";
                    }

                    if (urlStr.contains(".jar!")) {
                        String jarPath = urlStr.substring(0, urlStr.indexOf("!")).replaceFirst("^jar:file:", "");
                        File jarFile = new File(jarPath);
                        long time = jarFile.lastModified();
                        String formattedTime = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new Date(time));
                        return "Class from core or dependency library, last modified: " + formattedTime;
                    }

                    if (urlStr.contains("/WEB-INF/classes/") || urlStr.contains(File.separator + "WEB-INF" + File.separator + "classes" + File.separator)) {
                        return "Class from deployment directory: should be safe";
                    }

                    return null;

                } catch (Exception e) {
                    return "Unable to determine";
                }
            }





        %>

        <%
            out.write("<h2>TomcatMemshellScanner</h2>");
            String action = request.getParameter("action");
            String filterName = request.getParameter("filterName");
            String servletName = request.getParameter("servletName");
            String listenerName = request.getParameter("listenerName");
            String className = request.getParameter("className");
            String tomcatValve = request.getParameter("tomcatValve");
            String threadName = request.getParameter("threadName");
            String webSocket = request.getParameter("webSocket");
            String upgrade = request.getParameter("upgrade");
            String executors = request.getParameter("executor");

            //获取ServletContext对象(得到的其实是ApplicationContextFacade对象)
            ServletContext servletContext = request.getServletContext();
            StandardContext standardContext = null;
            //从 request 的 ServletContext 对象中循环判断获取 Tomcat StandardContext对象
            while (standardContext == null) {
                //因为是StandardContext对象是私有属性，所以需要用反射去获取
                Field f = servletContext.getClass().getDeclaredField("context");
                f.setAccessible(true);
                Object object = f.get(servletContext);

                if (object instanceof ServletContext) {
                    servletContext = (ServletContext) object;
                } else if (object instanceof StandardContext) {
                    standardContext = (StandardContext) object;
                }
            }
            Pipeline pipeline = standardContext.getPipeline();
            Valve[] valves = pipeline.getValves();

            if (action != null && action.equals("kill") && filterName != null) {
                deleteFilter(request, filterName);
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");
            } else if (action != null && action.equals("kill") && servletName != null) {
                deleteServlet(request, servletName);
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");
            }else if(action != null && action.equals("kill") && listenerName != null){
                deleteListener(request,listenerName);
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");
            }else if (action != null && action.equals("kill") && tomcatValve != null){
                int id = Integer.valueOf(tomcatValve).intValue();
                if(id!=0 & id!=valves.length-1 ){
                    pipeline.removeValve(valves[id]);
                    out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");

                }
            }else if(action!=null && action.equals("kill") && threadName!= null){
                Thread[] threads = (Thread[]) ((Thread[]) getField(Thread.currentThread().getThreadGroup(), "threads"));
                for (Thread thread : threads) {
                    if(threadName.equals(thread.getName())){
                        Class clzTimerThread = thread.getClass();
                        Field queueField = clzTimerThread.getDeclaredField("queue");
                        queueField.setAccessible(true);
                        //Timer里面的TaskQueue()对象
                        Object queue = queueField.get(thread);
                        Class clzTaskQueue = queue.getClass();
                        Method getTimeTask = clzTaskQueue.getDeclaredMethod("get",int.class);
                        getTimeTask.setAccessible(true);
                        //从TaskQueue对象中获取TimerTask，然后取消这个TimerTask以清除任务。
                        TimerTask timerTask = (TimerTask) getTimeTask.invoke(queue,1);
                        if(timerTask!=null){
                            timerTask.cancel();
                            out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");
                            break;

                        }
                    }
                }
            } else if(action!=null && action.equals("kill") && webSocket!= null){
                WsServerContainer wsServerContainer = (WsServerContainer) servletContext.getAttribute(ServerContainer.class.getName());

                // 利用反射获取 WsServerContainer 类中的私有变量 configExactMatchMap
                Class<?> obj = Class.forName("org.apache.tomcat.websocket.server.WsServerContainer");
                Field field = obj.getDeclaredField("configExactMatchMap");
                field.setAccessible(true);
                Map<String, Object> configExactMatchMap = (Map<String, Object>) field.get(wsServerContainer);

                // 遍历configExactMatchMap, 打印所有注册的 websocket 服务
                Set<String> keyset = configExactMatchMap.keySet();

                configExactMatchMap.remove(webSocket);
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");



            }else if(action!=null && action.equals("kill") && upgrade!= null){
                Request request1 =(Request) getField(request, "request");;
                Connector realConnector = (Connector) getField(request1, "connector");
                AbstractHttp11Protocol handler = (AbstractHttp11Protocol) getField(realConnector, "protocolHandler");
                HashMap<String, UpgradeProtocol> upgradeProtocols = (HashMap<String, UpgradeProtocol>) getField(handler,"httpUpgradeProtocols");
                upgradeProtocols.remove(upgrade);
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");



            }else if(action!=null && action.equals("kill") && executors!= null){
                NioEndpoint nioEndpoint = null;
                try {
                    nioEndpoint = (NioEndpoint) getNioEndpoint();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                ThreadPoolExecutor executor = (ThreadPoolExecutor)nioEndpoint.getExecutor();

                nioEndpoint.setExecutor(new org.apache.tomcat.util.threads.ThreadPoolExecutor(executor.getCorePoolSize(), executor.getMaximumPoolSize(),
                        executor.getKeepAliveTime(TimeUnit.MILLISECONDS), TimeUnit.MILLISECONDS, executor.getQueue(),
                        executor.getThreadFactory(), executor.getRejectedExecutionHandler()));
                out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");

            } else if ("dump".equals(action) && className != null) {
                try {
                    Class<?> clazz = Class.forName(className);
                    byte[] classBytes = Repository.lookupClass(clazz).getBytes();

                    // 设置响应头，确保异常前没有调用response.getWriter()或out写内容
                    response.reset();
                    response.setContentType("application/octet-stream");
                    String filename = clazz.getSimpleName() + ".class";
                    String agent = request.getHeader("User-Agent");

                    if (agent != null && agent.toLowerCase().contains("chrome")) {
                        response.setHeader("Content-Disposition", "attachment;filename=" + new String(filename.getBytes("UTF-8"), "ISO8859-1"));
                    } else {
                        response.setHeader("Content-Disposition", "attachment;filename=" + URLEncoder.encode(filename, "UTF-8"));
                    }

                    ServletOutputStream outDumper = response.getOutputStream();
                    outDumper.write(classBytes);
                    outDumper.flush();
                    outDumper.close();

                    return;

                } catch (Exception e) {
                    response.reset();
                    response.setContentType("text/html;charset=UTF-8");

                    out.write("<div style='color:darkred; font-weight:bold;'>Use Arthas for decompilation</div>");
                    out.write("<div>Project URL: <a href='https://github.com/alibaba/arthas' target='_blank'>https://github.com/alibaba/arthas</a></div>");
                    out.write("<pre style='background:#f0f0f0; padding:10px; border:1px solid #ccc;'>");
                    out.write("$ java -jar arthas-boot.jar\n");
                    out.write("$ jad --source-only " + className);
                    out.write("</pre>");
                    out.write("<input type=\"button\" name=\"Submit\" onclick=\"javascript:window.location.replace(document.referrer);\" value=\"Go back\">");
                    out.flush();

                    return;
                }
            } else {
                // Scan filter
                out.write("<h4>Filter Scan Results</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Filter Name</th>\n" +
                        "        <th width=\"10%\">Pattern</th>\n" +
                        "        <th width=\"20%\">Filter Class</th>\n" +
                        "        <th width=\"20%\">Filter ClassLoader</th>\n" +
                        "        <th width=\"25%\">Filter Class File Path</th>\n" +
                        "        <th width=\"10%\">Analysis Result</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                HashMap<String, Object> filterConfigs = getFilterConfig(request);
                Object[] filterMaps1 = getFilterMaps(request);
                for (int i = 0; i < filterMaps1.length; i++) {
                    out.write("<tr>");
                    Object fm = filterMaps1[i];
                    Object appFilterConfig = filterConfigs.get(getFilterName(fm));
                    if (appFilterConfig == null) {
                        continue;
                    }
                    Field _filter = appFilterConfig.getClass().getDeclaredField("filter");
                    _filter.setAccessible(true);
                    Object filter = _filter.get(appFilterConfig);
                    String filterClassName = filter.getClass().getName();
                    String filterClassLoaderName = filter.getClass().getClassLoader().getClass().getName();
                    // ID Filtername 匹配路径 className classLoader 是否存在file dump kill
                    out.write(String.format(
                            "<td style=\"text-align:center\">%d</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=kill&filterName=%s\">kill</a></td>",
                            i + 1,
                            getFilterName(fm),
                            arrayToString(getURLPatterns(fm)),
                            filterClassName,
                            filterClassLoaderName,
                            classFileIsExists(filter.getClass()),
                            judgeClassLocation(filter.getClass()),
                            filterClassName,
                            getFilterName(fm)
                    ));
                }

                out.write("</tbody></table>");
                // Scan servlet
                out.write("<h4>Servlet Scan Results</h4>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Servlet Name</th>\n" +
                        "        <th width=\"10%\">Pattern</th>\n" +
                        "        <th width=\"20%\">Servlet Class</th>\n" +
                        "        <th width=\"20%\">Servlet ClassLoader</th>\n" +
                        "        <th width=\"25%\">Servlet Class File Path</th>\n" +
                        "        <th width=\"10%\">Analysis Result</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                HashMap<String, Object> children = getChildren(request);
                Map<String, String> servletMappings = getServletMaps(request);

                int servletId = 0;
                for (Map.Entry<String, String> map : servletMappings.entrySet()) {
                    String servletMapPath = map.getKey();
                    String servletName1 = map.getValue();
                    StandardWrapper wrapper = (StandardWrapper) children.get(servletName1);

                    Class servletClass = null;
                    try {
                        servletClass = Class.forName(wrapper.getServletClass());
                    } catch (Exception e) {
                        Object servlet = wrapper.getServlet();
                        if (servlet != null) {
                            servletClass = servlet.getClass();
                        }
                    }
                    if (servletClass != null) {
                        out.write("<tr>");
                        String servletClassName = servletClass.getName();
                        String servletClassLoaderName = null;
                        try {
                            servletClassLoaderName = servletClass.getClassLoader().getClass().getName();
                        } catch (Exception e) {
                        }
                        out.write(String.format(
                                "<td style=\"text-align:center\">%d</td>" +
                                        "<td>%s</td>" +
                                        "<td>%s</td>" +
                                        "<td>%s</td>" +
                                        "<td>%s</td>" +
                                        "<td>%s</td>" +
                                        "<td>%s</td>" +
                                        "<td style=\"text-align:center\">" + "<a href=\"?action=dump&className=%s\">dump</a>" + "</td>" +
                                        "<td style=\"text-align:center\">" + "<a href=\"?action=kill&servletName=%s\">kill</a>" + "</td>"
                                , servletId + 1
                                , servletName1
                                , servletMapPath
                                , servletClassName
                                , servletClassLoaderName
                                , classFileIsExists(servletClass)
                                , judgeClassLocation(servletClass)
                                , servletClassName
                                , servletName1));
                        out.write("</tr>");
                    }
                    servletId++;
                }
                out.write("</tbody></table>");

                List<Object> listeners = getListenerList(request);
                out.write("<tbody>");
                List<ServletRequestListener> newListeners = new ArrayList<>();
                for (Object o : listeners) {
                    if (o instanceof ServletRequestListener) {
                        newListeners.add((ServletRequestListener) o);
                    }
                }

                // Scan listener
                out.write("<h4>Listener Scan Results</h4>");

                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"20%\">Listener Class</th>\n" +
                        "        <th width=\"30%\">Listener ClassLoader</th>\n" +
                        "        <th width=\"35%\">Listener Class File Path</th>\n" +
                        "        <th width=\"10%\">Analysis Result</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                int index = 0;
                for (ServletRequestListener listener : newListeners) {
                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=kill&listenerName=%s\">kill</a></td>"
                            , index + 1
                            , listener.getClass().getName()
                            , listener.getClass().getClassLoader()
                            , classFileIsExists(listener.getClass())
                            , judgeClassLocation(listener.getClass())
                            , listener.getClass().getName()
                            , listener.getClass().getName()));
                    out.write("</tr>");
                    index++;
                }
                out.write("</tbody></table>");




                out.write("<h4>Tomcat Valve Scan Results</h4>");
                out.write("<p>Note: Normally there should only be two valves (don't kill the wrong one!). Standard check process: examine class, class loader, dump and analyze.</p>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Tomcat Valve Class</th>\n" +
                        "        <th width=\"10%\">Tomcat Valve ClassLoader</th>\n" +
                        "        <th width=\"35%\">Tomcat Valve Class File Path</th>\n" +
                        "        <th width=\"10%\">Analysis Result</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                for (int i = 0; i < valves.length; i++) {
                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=kill&tomcatValve=%s\">kill</a></td>"
                            , i
                            , valves[i]
                            , valves[i].getClass().getClassLoader()
                            , classFileIsExists(valves[i].getClass())
                            , judgeClassLocation(valves[i].getClass())
                            , valves[i].getClass().getName()
                            , i));
                    out.write("</tr>");
                }
                out.write("</tbody></table>");


                //Timer scan
                out.write("<h4>Timer Scan Results</h4>");
                out.write("<p>Note: Memory shells implemented via Java timer tasks. Usually requires multi-threaded requests to execute commands (typically no response). Standard check process: examine class, class loader, dump and analyze.</p>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Thread Name</th>\n" +
                        "        <th width=\"10%\">TimerTask Class</th>\n" +
                        "        <th width=\"10%\">TimerTask ClassLoader</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");
                Thread[] threads = (Thread[]) ((Thread[]) getField(Thread.currentThread().getThreadGroup(), "threads"));
                int ii =0;
                for (Thread thread : threads) {
                    if (thread != null) {
                        if("java.util.TimerThread".equals(thread.getClass().getName())){

                            Class clzTimerThread = thread.getClass();
                            Field queueField = clzTimerThread.getDeclaredField("queue");
                            queueField.setAccessible(true);
                            //Timer里面的TaskQueue()对象
                            Object queue = queueField.get(thread);

                            Class clzTaskQueue = queue.getClass();
                            Method getTimeTask = clzTaskQueue.getDeclaredMethod("get",int.class);
                            getTimeTask.setAccessible(true);
                            //从TaskQueue对象中获取TimerTask，然后取消这个TimerTask以清除任务。
                            TimerTask timerTask = (TimerTask) getTimeTask.invoke(queue,1);
                            if(timerTask!=null){
                                //timerTask.cancel();
                                out.write("<tr>");
                                out.write(String.format("<td style=\"text-align:center\">%d</td>" +
                                                "<td>%s</td>" +
                                                "<td>%s</td>" +
                                                "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                                "<td style=\"text-align:center\"><a href=\"?action=kill&threadName=%s\">kill</a></td>"
                                        , ii
                                        , thread.getName()
                                        , timerTask.getClass().getName()
                                        , timerTask.getClass().getClassLoader()
                                        , timerTask.getClass().getName()
                                        , thread.getName()));
                                out.write("</tr>");
                                ii++;
                            }
                        }
                    }
                }
                out.write("</tbody></table>");




                out.write("<h4>WebSocket Scan Results</h4>");
                out.write("<p>Note: Treat this like a Servlet. If the current service doesn't use WebSocket and something appears here, it's definitely a memory shell.</p>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">WebSocket Name</th>\n" +
                        "        <th width=\"10%\">Pattern</th>\n" +
                        "        <th width=\"10%\">WebSocket Class</th>\n" +
                        "        <th width=\"10%\">WebSocket ClassLoader</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                // 通过 request 的 context 获取 ServerContainer
                WsServerContainer wsServerContainer = (WsServerContainer) request.getServletContext().getAttribute(ServerContainer.class.getName());

                // 利用反射获取 WsServerContainer 类中的私有变量 configExactMatchMap
                Class<?> obj = Class.forName("org.apache.tomcat.websocket.server.WsServerContainer");
                Field field = obj.getDeclaredField("configExactMatchMap");
                field.setAccessible(true);
                Map<String, Object> configExactMatchMap = (Map<String, Object>) field.get(wsServerContainer);

                // 遍历configExactMatchMap, 打印所有注册的 websocket 服务
                Set<String> keyset = configExactMatchMap.keySet();
                Iterator<String> iterator = keyset.iterator();


                int j = 0;
                while (iterator.hasNext()) {
                    String key = iterator.next();
                    Object object = wsServerContainer.findMapping(key);
                    Class<?> wsMappingResultObj = Class.forName("org.apache.tomcat.websocket.server.WsMappingResult");
                    Field configField = wsMappingResultObj.getDeclaredField("config");
                    configField.setAccessible(true);
                    ServerEndpointConfig config1 = (ServerEndpointConfig)configField.get(object);
                    Class<?> clazz = config1.getEndpointClass();



                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=kill&webSocket=%s\">kill</a></td>"
                            , j
                            , clazz.getSimpleName()
                            , key
                            , clazz.getName()
                            , clazz.getClassLoader()
                            , judgeClassLocation(clazz.getClass())
                            , clazz.getName()
                            , key));
                    out.write("</tr>");

                    j++;
                }

                out.write("</tbody></table>");


                out.write("<h4>Upgrade Protocol Scan Results</h4>");
                out.write("<p>Note: Normally there should be no Upgrade protocols. If results appear, 99% chance it's a memory shell. The remaining 1% - dump and analyze the process to confirm.</p>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"5%\">ID</th>\n" +
                        "        <th width=\"10%\">Upgrade Name</th>\n" +
                        "        <th width=\"10%\">Key</th>\n" +
                        "        <th width=\"10%\">Upgrade Class</th>\n" +
                        "        <th width=\"10%\">Upgrade ClassLoader</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Kill</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");

                Request request1 =(Request) getField(request, "request");;
                Connector realConnector = (Connector) getField(request1, "connector");
                AbstractHttp11Protocol handler = (AbstractHttp11Protocol) getField(realConnector, "protocolHandler");
                HashMap<String, UpgradeProtocol> upgradeProtocols = (HashMap<String, UpgradeProtocol>) getField(handler,"httpUpgradeProtocols");


                int aaa = 0;
                for (Map.Entry<String, UpgradeProtocol> entry : upgradeProtocols.entrySet()) {


                    out.write("<tr>");
                    out.write(String.format("<td style=\"text-align:center\">%d</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td>%s</td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td>" +
                                    "<td style=\"text-align:center\"><a href=\"?action=kill&upgrade=%s\">kill</a></td>"
                            , aaa
                            , entry.getValue().getClass().getSimpleName()
                            , entry.getKey()
                            , entry.getValue().getClass().getName()
                            , entry.getValue().getClass().getClassLoader()
                            , entry.getValue().getClass().getName()
                            , entry.getKey()));
                    out.write("</tr>");
                    aaa++;

                }
                out.write("</tbody></table>");


                out.write("<h4>Executor Shell Detection</h4>");
                out.write("<p>Note: Memory shell implemented by replacing the Executor thread pool object in NioEndpoint with a malicious object. Simple to detect - just check if the corresponding class is the original org.apache.tomcat.util.threads.ThreadPoolExecutor</p>");
                out.write("<table border=\"1\" cellspacing=\"0\" width=\"95%\" style=\"table-layout:fixed;word-break:break-all;background:#f2f2f2\">\n" +
                        "    <thead>\n" +
                        "        <th width=\"10%\">Executor Name</th>\n" +
                        "        <th width=\"10%\">Executor Class</th>\n" +
                        "        <th width=\"10%\">Executor ClassLoader</th>\n" +
                        "        <th width=\"5%\">Dump</th>\n" +
                        "        <th width=\"5%\">Restore</th>\n" +
                        "    </thead>\n" +
                        "    <tbody>");


                // 从线程中获取NioEndpoint类
                NioEndpoint nioEndpoint = null;
                try {
                    nioEndpoint = (NioEndpoint) getNioEndpoint();
                } catch (Exception e) {
                    e.printStackTrace();
                }
                ThreadPoolExecutor executor = (ThreadPoolExecutor)nioEndpoint.getExecutor();


                out.write("<tr>");
                out.write(String.format("<td>%s</td><td>%s</td><td>%s</td><td style=\"text-align:center\"><a href=\"?action=dump&className=%s\">dump</a></td><td style=\"text-align:center\"><a href=\"?action=kill&executor=%s\">kill</a></td>"
                        , executor.getClass().getSimpleName()
                        , executor.getClass().getName()
                        , executor.getClass().getClassLoader()
                        , executor.getClass().getName()
                        , "recovery"));
                out.write("</tr>");
                out.write("</tbody></table>");
            }
        %>
    </div>
    <br/>
</center>
</body>
</html>
