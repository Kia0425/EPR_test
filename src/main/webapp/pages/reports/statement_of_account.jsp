<%@page import="com.jsh.util.Tools"%>
<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>
<%
	String path = request.getContextPath();
	String clientIp = Tools.getLocalIp(request);
%>
<!DOCTYPE html>
<html>
  	<head>
    	<title>对账单</title>
        <meta charset="utf-8">
		<!-- 指定以IE8的方式来渲染 -->
		<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE8"/>
    	<link rel="shortcut icon" href="<%=path%>/images/favicon.ico" type="image/x-icon" />
    	<script type="text/javascript" src="<%=path %>/js/jquery-1.8.0.min.js"></script>
		<script type="text/javascript" src="<%=path %>/js/print/print.js"></script>
		<link rel="stylesheet" type="text/css" href="<%=path %>/js/easyui-1.3.5/themes/default/easyui.css"/>
		<link rel="stylesheet" type="text/css" href="<%=path %>/js/easyui-1.3.5/themes/icon.css"/>
		<link type="text/css" rel="stylesheet" href="<%=path %>/css/common.css" />
		<script type="text/javascript" src="<%=path %>/js/easyui-1.3.5/jquery.easyui.min.js"></script>
		<script type="text/javascript" src="<%=path %>/js/easyui-1.3.5/locale/easyui-lang-zh_CN.js"></script>
		<script type="text/javascript" src="<%=path %>/js/My97DatePicker/WdatePicker.js"></script>
		<script type="text/javascript" src="<%=path %>/js/common/common.js"></script>
		<script>
			var uid = ${sessionScope.user.id};
		</script>
  	</head>
  	<body>
  		<!-- 查询 -->
		<div id = "searchPanel"	class="easyui-panel" style="padding:10px;" title="查询窗口" iconCls="icon-search" collapsible="true" closable="false">
			<table id="searchTable">
				<tr>
					<td>单位名称：</td>
					<td>
						<input id="OrganId" name="OrganId" style="width:100px;" />
					</td>
					<td>&nbsp;</td>
					<td>单据日期：</td>
					<td>
						<input type="text" name="searchBeginTime" id="searchBeginTime" onClick="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'})" class="txt Wdate" style="width:140px;"/>
					</td>
					<td>-</td>
					<td>
						<input type="text" name="searchEndTime" id="searchEndTime" onClick="WdatePicker({dateFmt:'yyyy-MM-dd HH:mm:ss'})" class="txt Wdate" style="width:140px;"/>
					</td>
					<td>&nbsp;</td>
					<td>
						<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-search" id="searchBtn">查询</a>
						&nbsp;&nbsp;
						<a href="javascript:void(0)" class="easyui-linkbutton" iconCls="icon-print" id="printBtn">打印</a>
					</td>
				</tr>
			</table>
		</div>
		
		<!-- 数据显示table -->
		<div id = "tablePanel"	class="easyui-panel" style="padding:1px;top:300px;" title="对账单列表" iconCls="icon-list" collapsible="true" closable="false">
			<table id="tableData" style="top:300px;border-bottom-color:#FFFFFF"></table>
		</div>
			    
		<script type="text/javascript">
			var path = "<%=path %>";
			var cusUrl = path + "/supplier/findBySelect_cus.action?UBType=UserCustomer&UBKeyId=" + uid; //客户接口
			//初始化界面
			$(function()
			{
				var thisDate = getNowFormatMonth(); //当前月份
				var thisDateTime = getNowFormatDateTime(); //当前时间
				$("#searchBeginTime").val(thisDate + "-01 00:00:00");
				$("#searchEndTime").val(thisDateTime);
				initSupplier(); //初始化供应商、客户信息
				initTableData();
				ininPager();
				search();
				print();
			});	


			//初始化供应商、客户
			function initSupplier(){
				$('#OrganId').combobox({
					url: cusUrl,
					valueField:'id',
					textField:'supplier',
					filter: function(q, row){
						var opts = $(this).combobox('options');
						return row[opts.textField].indexOf(q) >-1;
					}
				});
			}
			
			//初始化表格数据
			function initTableData()
			{
				$('#tableData').datagrid({
					height:heightInfo,
					nowrap: false,
					rownumbers: true,
					//动画效果
					animate:false,
					//选中单行
					singleSelect : true,
					pagination: true,
					//交替出现背景
					striped : true,
					pageSize: 10,
					pageList: [10,50,100],
					columns:[[
			          	{ title: '单据编号',field: 'number',width:140},
						{ title: '单位名称',field: 'supplierName',width:200},
						{ title: '金额',field: 'allPrice',width:60,formatter: function(value,rec){
							return (rec.changeAmount-rec.totalPrice).toFixed(2);
						}},
						{ title: '单据日期',field: 'operTime',width:140}
					]],
					onLoadError:function()
					{
						$.messager.alert('页面加载提示','页面加载异常，请稍后再试！','error');
						return;
					}    
				});
			}
			
			//初始化键盘enter事件
			$(document).keydown(function(event)
			{  
			   	//兼容 IE和firefox 事件 
			    var e = window.event || event;  
			    var k = e.keyCode||e.which||e.charCode;  
			    //兼容 IE,firefox 兼容  
			    var obj = e.srcElement ? e.srcElement : e.target;  
			    //绑定键盘事件为 id是指定的输入框才可以触发键盘事件 13键盘事件 ---遗留问题 enter键效验 对话框会关闭问题
			    if(k == "13"&&(obj.id=="Type"||obj.id=="Name"))
			    {  
			        $("#savePerson").click();
			    }
			    //搜索按钮添加快捷键
			    if(k == "13"&&(obj.id=="searchType"))
			    {  
			        $("#searchBtn").click();
			    }  
			}); 
			//分页信息处理
			function ininPager()
			{
				try
				{
					var opts = $("#tableData").datagrid('options');  
					var pager = $("#tableData").datagrid('getPager'); 
					pager.pagination({  
						onSelectPage:function(pageNum, pageSize)
						{  
							opts.pageNumber = pageNum;  
							opts.pageSize = pageSize;  
							pager.pagination('refresh',
							{  
								pageNumber:pageNum,  
								pageSize:pageSize  
							});  
							showDetails(pageNum,pageSize);
						}  
					}); 
				}
				catch (e) 
				{
					$.messager.alert('异常处理提示',"分页信息异常 :  " + e.name + ": " + e.message,'error');
				}
			}
			
			//增加
			var url;
			var personID = 0;
			//保存编辑前的名称
			var orgPerson = "";

			//搜索处理
			function search() {
				showDetails(1,initPageSize);
				var opts = $("#tableData").datagrid('options');
				var pager = $("#tableData").datagrid('getPager');
				opts.pageNumber = 1;
				opts.pageSize = initPageSize;
				pager.pagination('refresh',
				{
					pageNumber:1,
					pageSize:initPageSize
				});
			}
			$("#searchBtn").unbind().bind({
				click:function()
				{
					search();
				}
			});
			
			function showDetails(pageNo,pageSize)
			{
				$.ajax({
					type: "post",
					url: "<%=path %>/depotHead/findStatementAccount.action",
					dataType: "json",
					data: ({
						pageNo:pageNo,
						pageSize:pageSize,
						BeginTime: $("#searchBeginTime").val(),
						EndTime: $("#searchEndTime").val(),
						OrganId: $('#OrganId').combobox('getValue')
					}),
					success: function (res) {
						if(res){
							$("#tableData").datagrid('loadData',res);
						}
					},
					//此处添加错误处理
					error:function() {
						$.messager.alert('查询提示','查询数据后台异常，请稍后再试！','error');
						return;
					}
				});
			}
			//报表打印
			function print() {
				$("#printBtn").off("click").on("click",function(){
					var path = "<%=path %>";
					CreateFormPage('打印报表', $('#tableData'), path);
				});
			}
		</script>
	</body>
</html>