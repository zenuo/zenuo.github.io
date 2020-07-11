---
layout: post
---

闲话少叙，借助[chinese-poetry](https://github.com/zenuo/chinese-poetry)项目的数据，用以下Go代码实现读取部分JSON文件并写入MySQL数据库，首先创建数据库：

```sql
CREATE DATABASE `chinese-poetry` CHARACTER SET 'utf8mb4';
```

## 诗表

```sql
CREATE TABLE `poet` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `dynasty`varchar(11) DEFAULT NULL,
  `author` text DEFAULT NULL,
  `paragraph` text DEFAULT NULL,
  `strains` text DEFAULT NULL,
  `title` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 词表

```sql
CREATE TABLE `ci` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `dynasty`varchar(11) DEFAULT NULL,
  `author` text DEFAULT NULL,
  `paragraph` text DEFAULT NULL,
  `rhythmic` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 诗经表

```sql
CREATE TABLE `shijing` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `title` text DEFAULT NULL,
  `chapter` text DEFAULT NULL,
  `section`varchar(11) DEFAULT NULL,
  `content` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

然后需要安装依赖库：

```bash
$ go get -u github.com/jinzhu/gorm
$ go get -u github.com/go-sql-driver/mysql
```

接下来就是代码部分，可以查看[chinese-poetry项目中的main.go](https://github.com/zenuo/chinese-poetry/blob/master/mysql/main.go)：

```go
package main

import (
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

// PoetInJSON 诗
type PoetInJSON struct {
	Author     string   `json:"author"`
	Paragraphs []string `json:"paragraphs"`
	Strains    []string `json:"strains"`
	Title      string   `json:"title"`
}

// CiInJSON 词
type CiInJSON struct {
	Author     string   `json:"author"`
	Paragraphs []string `json:"paragraphs"`
	Rhythmic   string   `json:"rhythmic"`
}

// ShiJingInJSON 诗经
type ShiJingInJSON struct {
	Title   string   `json:"title"`
	Chapter string   `json:"chapter"`
	Section string   `json:"section"`
	Content []string `json:"content"`
}

func main() {
	// 打开数据库连接
	db, _ := gorm.Open("mysql", "app:123456@tcp(localhost:3306)/chinese-poetry?charset=utf8mb4&parseTime=True&loc=Local")
	// 插入诗
	// err := InsertPoet(db)
	// if err != nil {
	// 	panic(err)
	// }
	//插入词
	// err := InsertCi(db)
	// if err != nil {
	// 	panic(err)
	// }
	//插入诗经InsertShijing
	err := InsertShijing(db)
	if err != nil {
		panic(err)
	}
	defer db.Close()
}

// InsertPoet 读取诗并INSERT到数据库
func InsertPoet(db *gorm.DB) error {
	tx := db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	//遍历文件夹
	files, err := ioutil.ReadDir(filepath.Join("..", "shi"))
	if err != nil {
		log.Fatal(err)
		panic(err)
	}
	//正则模式
	validPattern := regexp.MustCompile(`^poet\.(.+?)\.[0-9]+\.json`)
	for _, file := range files {
		//若匹配
		if validPattern.MatchString(file.Name()) {
			//捕获朝代
			dynasty := validPattern.FindStringSubmatch(file.Name())[1]
			//读取文件
			jsonFile, err := os.Open(filepath.Join("..", "shi", file.Name()))
			if err != nil {
				log.Panic(err)
				panic(err)
			}
			byteValue, _ := ioutil.ReadAll(jsonFile)
			defer jsonFile.Close()

			//解组
			var poets []PoetInJSON
			err1 := json.Unmarshal(byteValue, &poets)
			if err1 != nil {
				panic(err1)
			}

			//遍历
			for _, poet := range poets {
				//执行INSERT
				if err := tx.Exec("INSERT INTO `poet` (`author`,`paragraph`,`strains`,`title`,`dynasty`) VALUES (?,?,?,?,?)", poet.Author, strings.Join(poet.Paragraphs, ""), strings.Join(poet.Strains, ""), poet.Title, dynasty).Error; err != nil {
					log.Panicf("%s, %s", poet, err)
					//回滚
					tx.Rollback()
					return err
				}
			}
		}
	}

	return tx.Commit().Error
}

// InsertCi 读取词并INSERT到数据库
func InsertCi(db *gorm.DB) error {
	tx := db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	//遍历文件夹
	files, err := ioutil.ReadDir(filepath.Join("..", "ci"))
	if err != nil {
		log.Fatal(err)
		panic(err)
	}
	//正则模式
	validPattern := regexp.MustCompile(`^ci\.song\.[0-9]+\.json`)
	for _, file := range files {
		//若匹配
		if validPattern.MatchString(file.Name()) {
			dynasty := "song"
			//读取文件
			jsonFile, err := os.Open(filepath.Join("..", "ci", file.Name()))
			if err != nil {
				log.Panic(err)
				panic(err)
			}
			byteValue, _ := ioutil.ReadAll(jsonFile)
			defer jsonFile.Close()

			//解组
			var cis []CiInJSON
			err1 := json.Unmarshal(byteValue, &cis)
			if err1 != nil {
				panic(err1)
			}

			//遍历
			for _, ci := range cis {
				//执行INSERT
				if err := tx.Exec("INSERT INTO `ci` (`author`,`paragraph`,`rhythmic`,`dynasty`) VALUES (?,?,?,?)", ci.Author, strings.Join(ci.Paragraphs, ""), ci.Rhythmic, dynasty).Error; err != nil {
					log.Panicf("%s, %s", ci, err)
					//回滚
					tx.Rollback()
					return err
				}
			}
		}
	}

	return tx.Commit().Error
}

// InsertShijing 读取诗经并INSERT到数据库
func InsertShijing(db *gorm.DB) error {
	tx := db.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	//读取文件
	jsonFile, err := os.Open(filepath.Join("..", "shijing", "shijing.json"))
	if err != nil {
		log.Panic(err)
		panic(err)
	}
	byteValue, _ := ioutil.ReadAll(jsonFile)
	defer jsonFile.Close()

	//解组
	var shijings []ShiJingInJSON
	err1 := json.Unmarshal(byteValue, &shijings)
	if err1 != nil {
		panic(err1)
	}

	//遍历
	for _, shijing := range shijings {
		//执行INSERT
		if err := tx.Exec("INSERT INTO `shijing` (`title`,`chapter`,`section`,`content`) VALUES (?,?,?,?)", shijing.Title, shijing.Chapter, shijing.Section, strings.Join(shijing.Content, "")).Error; err != nil {
			log.Panicf("%s, %s", shijing, err)
			//回滚
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}
```

# 参考

- https://mholt.github.io/json-to-go/
- https://mariadb.com/kb/en/library/auto_increment/
- https://play.golang.org/
- https://stackoverflow.com/questions/30483652/how-to-get-capturing-group-functionality-in-golang-regular-expressions
- https://regexr.com/
- https://golang.org/pkg/regexp/
- https://golang.org/pkg/path/filepath/
- https://flaviocopes.com/go-list-files/
- https://gobyexample.com/string-functions
- https://stackoverflow.com/questions/38867692/parse-json-array-in-golang
- https://blog.golang.org/json-and-go