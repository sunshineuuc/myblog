---
title: PHP获取系统详细信息-CPU、内存、磁盘、负载
date: 2020-04-16 14:39:16
tags:
- PHP
categories:
- 开发者手册
---

#### 引言 ####

本文使用PHP获取服务器的状态，包括负载、CPU、磁盘和内存的使用率等信息，另外还支持检查进程是否存在，目前支持Windows和Linux两种平台下使用。
<!-- more -->

---

#### 代码实现 ####

```php
class System_info
{
    protected $is_win = false;// 是否是Windows操作系统

    // 如果是Linux操作系统则自动获取CPU/内存的使用率
    protected $lin_cpu_usage = null;
    protected $lin_mem_usage = null;

    public function __construct()
    {
        $this->is_win = is_running_on_windows();
    }

    /**
     * Linux操作系统自动获取CPU(内存)使用率
     */
    private function get_lin_status()
    {
        $fp = popen('top -b -n 2 | grep -E "(Cpu\(s\))|(KiB Mem)"', "r");
        $rs = '';
        while (!feof($fp)) {
            $rs .= fread($fp, 1024);
        }
        pclose($fp);

        $sys_info = explode('\n', $rs);
        $cpu_info = explode(',', $sys_info[2]);
        $this->lin_cpu_usage = trim(trim($cpu_info[0], '%Cpu(s): '), 'us');

        $mem_info = explode(",", $sys_info[3]); //内存占有量 数组
        $mem_total = trim(trim($mem_info[0], 'KiB Mem : '), ' total');
        $mem_used = trim(trim($mem_info[2], 'used'));
        $this->lin_mem_usage = round(100 * intval($mem_used) /     intval($mem_total), 2);
    }

    /**
     * 判断指定路径下指定文件是否存在，不存在则创建，Windows环境下使用
     * @param $file_name
     * @param $content
     * @return string
     */
    private function get_file_path($file_name, $content)
    {
         $path = dirname(__FILE__) . "/{$file_name}";
         if (!file_exists($path)) {
             file_put_contents($path, $content);
         }
         return $path;
    }

    /**
     * @return string 返回cpu使用率函数文件路径， Windows环境下使用
     */
    private function get_cpu_usage_vbs_path()
    {
        return $this->get_file_path(
            'cpu_usage.vbs',
            "On Error Resume Next
    Set objProc = GetObject(\"winmgmts:\\\\.\\root\cimv2:win32_processor='cpu0'\")
    WScript.Echo(objProc.LoadPercentage)"
        );
    }

    /**
     * @return string 返回总内存及可用物理内存函数文件路径， Windows环境下使用
     */
    private function get_mem_usage_path()
    {
        return $this->get_file_path(
            'memory_usage.vbs',
            "On Error Resume Next
    Set objWMI = GetObject(\"winmgmts:\\\\.\\root\cimv2\")
    Set colOS = objWMI.InstancesOf(\"Win32_OperatingSystem\")
    For Each objOS in colOS
     Wscript.Echo(\"{\"\"TotalVisibleMemorySize\"\":\" & objOS.TotalVisibleMemorySize & \",\"\"FreePhysicalMemory\"\":\" & objOS.FreePhysicalMemory & \"}\")
    Next"
        );
    }

    /**
     * @return mixed cpu usage， Windows环境下使用
     */
    public function get_cpu_usage()
    {
        if ($this->is_win) {
            $path = $this->get_cpu_usage_vbs_path();
            $retval = $this->exec("cscript -nologo \"{$path}\"", $usage);
            return intval($usage[0]);
        } else {
            is_null($this->lin_cpu_usage) and $this->get_lin_status();
            return $this->lin_cpu_usage;
        }
    }

    /**
     * @return mixed memory usage
     */
    public function get_mem_usage()
    {
        if ($this->is_win) {
            $path = $this->get_mem_usage_path();
            $retval = $this->exec("cscript -nologo \"$path\"", $usage);
            $memory = json_decode($usage[0], true);
            return Round((($memory['TotalVisibleMemorySize'] - $memory['FreePhysicalMemory']) / $memory['TotalVisibleMemorySize']) * 100);
        } else {
            is_null($this->lin_mem_usage) and $this->get_lin_status();
            return $this->lin_mem_usage;
        }
    }

    /**
     * @return array 磁盘使用率
     */
    public function get_hd_usage()
    {
        $storage = [];
        $sys_hd = $this->is_win ? 'C:' : '/';

        // 系统盘C: 或 linux下的/
        $hdc_free = disk_free_space($sys_hd);
        $hdc_total = disk_total_space($sys_hd);
        array_push($storage, ['label' => $sys_hd, 'value' => floor(100 * $hdc_free / $hdc_total) . '%']);

        return $storage;
    }

    /**
     * @return mixed|null 负载
     */
    public function get_load()
    {
        $load = null;

        if ($this->is_win) {
            $cmd = "WMIC CPU GET LOADPERCENTAGE /ALL";
            @exec($cmd, $output);// exp: LoadPercentage 9 4

            if ($output)
            {
                foreach ($output as $line)
                {
                    if ($line && preg_match("/^[0-9]+\$/", $line))
                    {
                        $load = $line;
                        break;
                    }
                }
            }
        } else {
            $sys_load = sys_getloadavg();
            $load = $sys_load[0];
        }

        return $load;
    }

    /* 检查指定进程是否存在 */
    public function check_if_process_exists($process_name)
    {
        $output = null;// init output

        // $process_name: Nginx QQ 
        $cmd = $this->is_win ? "TASKLIST | FINDSTR {$process_name}" : "ps -ax | grep {$process_name}";
        if ($this->is_win) {
            $this->exec($cmd, $output);
            if (!empty($output[0])) {
                return ON;
            }
        } else {
            $this->exec($cmd, $output);
            if (count($output) >= 2) {// ps查看进程最少会有两个，这里包含查询命令这一条
                return ON;
            }
        }

        return OFF;
    }

    /* 重新实现exec */
    protected function exec($cmd, &$out = null)
    {
        $desc = array(
            1 => array('pipe', 'w'),
            2 => array('pipe', 'w')
        );
        $proc = proc_open($cmd, $desc, $pipes);

        $ret = stream_get_contents($pipes[1]);
        $err = stream_get_contents($pipes[2]);

        fclose($pipes[1]);
        fclose($pipes[2]);

        $ret_val = proc_close($proc);

        if (func_num_args() == 2) {
            $out = array($ret, $err);
        }
        return $ret_val;
    }
    
    /* 检查系统类型：True: Windows   false:Linux */
    private function is_running_on_windows()
    {
        return (strtoupper(substr(PHP_OS, 0, 3)) === 'WIN'
            || substr(php_uname(), 0, 7) === 'Windows'
            || DIRECTORY_SEPARATOR == '\\');
    }
}
```

---

#### 使用方法 ####
```php
$sys = new System_info();
$load = $sys->get_load() . '%';// 当前负载
$cpu_usage = $sys->get_cpu_usage() . '%';// CPU使用率
$mem_usage = $sys->get_mem_usage() . '%';// 内存使用率
$storage  =  $sys->get_hd_usage(); // 存储
$nginx_exists = $sys->check_if_process_exists('Nginx');// 检查Nginx进程是否存在
```
