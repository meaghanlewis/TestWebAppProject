﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace TestWebAppProject.Controllers
{
    public class HomeController : Controller
    {
        public IActionResult Index()
        {
            return View();
            return View();
        }

        public IActionResult About()
        {

            return View();
        }

        public IActionResult Contact()
        {
            ViewData["Message"] = "Your contact page.";

            return View();
        }

    }
}
